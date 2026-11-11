(() => {
  'use strict';

  const MOD = '/data/adb/modules/stevenblock';
  const VERSION = 'v2.0';
  const VERSION_CODE = 2000;
  const RULE_MAX = 1000;
  const LEVEL = { green: '🟢', blue: '🔵', yellow: '🟡', orange: '🟠', red: '🔴' };
  const STEPS = [
    ['download', '⬇️', 'Download'],
    ['verify', '🔍', 'Verify'],
    ['optimize', '🧹', 'Optimize'],
    ['install', '📦', 'Install']
  ];
  const PHASE_TEXT = {
    prepare: '⏳ Preparing…',
    check: '🔎 Checking for updates…',
    download: '⬇️ Downloading…',
    verify: '🔍 Verifying the download…',
    optimize: '🧹 Cleaning and optimizing…',
    install: '📦 Installing the hosts file…',
    finish: '✨ Finishing up…'
  };
  const ADDON_GROUPS = [
    ['content', '🎭 Content categories'],
    ['security', '🔐 Security'],
    ['tracker', '📱 Device & app trackers'],
    ['custom', '🔗 Your own lists']
  ];
  const ADDON_WARN = {
    dns: '🔐 Encrypted DNS bypass blocks public DNS-over-HTTPS servers, so browsers and apps fall back to the system resolver. Your Android Private DNS provider stays reachable automatically.',
    heavy: '🐘 Threat Intelligence is very large. On some ROMs a hosts file with over a million entries makes DNS lookups slower.',
    breaks: '👥 Social networks blocks the networks themselves. Their apps and websites stop working.'
  };
  const AUTO_CHOICES = [[0, 'Off'], [1, 'Daily'], [3, '3 days'], [7, 'Weekly']];
  const AUTO_TEXT = { 0: 'Off', 1: 'Daily', 3: 'Every 3 days', 7: 'Weekly' };
  const POWER = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 3.2v8.4" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/><path d="M6.5 6.8a7.7 7.7 0 1 0 11 0" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>';
  const FAIL = {
    bridge: '❌ StevenBlock didn’t respond. Please try again.',
    offline: '🔌 The local WebUI server isn’t running anymore.',
    unauthorized: '🔑 This session has expired.',
    no_token: '🔑 No secure session was found.',
    framed: '🚫 StevenBlock can’t run inside another page.'
  };
  const ERR = {
    empty: '✏️ Enter a domain first.',
    space: '🚫 Spaces aren’t allowed in a domain.',
    wildcard: '🚫 A wildcard only works at the start of an allow rule, like *.example.com.',
    wildblock: '🚫 Hosts files can’t block wildcards. Enter the exact domain to block.',
    port: '🚫 Ports and IPv6 addresses aren’t allowed. Enter just the domain, like example.com.',
    ip: '🚫 IP addresses aren’t allowed. Enter a domain name instead.',
    invalid: '🚫 That doesn’t look like a valid domain. Example: ads.example.com'
  };

  const $ = (id) => document.getElementById(id);
  const nf = new Intl.NumberFormat('en-US');
  const dateFmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  const timeFmt = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
  const dayFmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' });
  const stampFmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false });

  const store = {
    get(key, session) {
      try {
        return (session ? window.sessionStorage : window.localStorage).getItem(key);
      } catch (e) {
        return null;
      }
    },
    set(key, value, session) {
      try {
        (session ? window.sessionStorage : window.localStorage).setItem(key, value);
      } catch (e) {
        return false;
      }
      return true;
    }
  };

  const S = {
    status: null,
    lists: null,
    refreshing: false,
    rules: { allow: [], block: [] },
    tab: 'allow',
    ruleFilter: '',
    logs: [],
    logSig: '',
    logLevel: 'all',
    op: null,
    busy: false,
    syncBusy: false,
    opView: false,
    seen: Number(store.get('sb-seq')) || 0,
    speed: { t: 0, b: 0, v: 0 },
    ready: false,
    gate: '',
    addonSel: null,
    lookup: null
  };

  function fmtNum(n) {
    return nf.format(Number(n) || 0);
  }

  function fmtMB(bytes) {
    const b = Math.max(0, Number(bytes) || 0);
    if (b < 1048576) return Math.max(b > 0 ? 1 : 0, Math.round(b / 1024)) + ' KB';
    return (b / 1048576).toFixed(1) + ' MB';
  }

  function fmtDate(sec) {
    return sec ? dateFmt.format(new Date(sec * 1000)) : 'Unknown';
  }

  function plural(n, one, many) {
    return Number(n) === 1 ? one : many;
  }

  function nowSec() {
    return Date.now() / 1000;
  }

  function ago(sec) {
    if (!sec) return 'Never';
    const d = Math.max(0, nowSec() - sec);
    if (d < 60) return 'just now';
    if (d < 3600) return Math.floor(d / 60) + ' min ago';
    if (d < 86400) return Math.floor(d / 3600) + ' h ago';
    const days = Math.floor(d / 86400);
    return days === 1 ? 'yesterday' : days + ' days ago';
  }

  function logTime(sec) {
    const d = new Date(sec * 1000);
    const now = new Date();
    if (d.toDateString() === now.toDateString()) return timeFmt.format(d);
    return dayFmt.format(d) + ' ' + timeFmt.format(d).slice(0, 5);
  }

  function stripLead(msg) {
    const s = String(msg || '');
    const i = s.indexOf(' ');
    if (i > 0 && i < 6 && !/[A-Za-z0-9]/.test(s.slice(0, i))) return s.slice(i + 1);
    return s;
  }

  function h(tag, props) {
    const el = document.createElement(tag);
    if (props) {
      Object.keys(props).forEach((key) => {
        const v = props[key];
        if (v === null || v === undefined || v === false) return;
        if (key === 'class') el.className = v;
        else if (key === 'text') el.textContent = v;
        else if (key === 'html') el.innerHTML = v;
        else if (key.indexOf('on') === 0) el.addEventListener(key.slice(2), v);
        else el.setAttribute(key, v === true ? '' : v);
      });
    }
    for (let i = 2; i < arguments.length; i++) {
      const c = arguments[i];
      if (c === null || c === undefined || c === false) continue;
      if (Array.isArray(c)) c.forEach((x) => { if (x) el.appendChild(typeof x === 'string' ? document.createTextNode(x) : x); });
      else el.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
    }
    return el;
  }

  function clear(el) {
    while (el.firstChild) el.removeChild(el.firstChild);
    return el;
  }

  function powerIcon() {
    return h('span', { class: 'pw', html: POWER });
  }

  function sk(cls) {
    return h('span', { class: 'sk ' + cls });
  }

  function para(text, cls) {
    return h('p', { class: cls || null, text: text });
  }

  function note(text, kind) {
    return h('div', { class: 'note' + (kind ? ' is-' + kind : ''), text: text });
  }

  const Bridge = (() => {
    const k = (typeof window.ksu === 'object' && window.ksu && typeof window.ksu.exec === 'function') ? window.ksu : null;
    let token = '';
    let seq = 0;
    let framed = false;
    if (!k) {
      try {
        framed = window.top !== window.self;
      } catch (e) {
        framed = true;
      }
      const m = /(?:^#|&)t=([0-9a-f]{32})(?:&|$)/.exec(window.location.hash || '');
      if (m) {
        token = m[1];
        store.set('sb-token', token, true);
        try {
          window.history.replaceState(null, '', window.location.pathname + window.location.search);
        } catch (e) {
          token = m[1];
        }
      } else {
        token = store.get('sb-token', true) || '';
      }
    }

    function forget(name) {
      try {
        delete window[name];
      } catch (e) {
        window[name] = undefined;
      }
    }

    function exec(command) {
      return new Promise((resolve, reject) => {
        const cb = 'sbcb_' + Date.now().toString(36) + '_' + (seq++).toString(36);
        const timer = setTimeout(() => {
          forget(cb);
          reject(new Error('timeout'));
        }, 120000);
        window[cb] = (errno, stdout, stderr) => {
          clearTimeout(timer);
          forget(cb);
          resolve({ errno: Number(errno) || 0, stdout: stdout === null || stdout === undefined ? '' : String(stdout), stderr: stderr === null || stderr === undefined ? '' : String(stderr) });
        };
        try {
          k.exec(command, JSON.stringify({}), cb);
        } catch (e) {
          clearTimeout(timer);
          forget(cb);
          reject(e);
        }
      });
    }

    function quote(s) {
      return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function parse(text) {
      const lines = String(text || '').trim().split('\n');
      for (let i = lines.length - 1; i >= 0; i--) {
        const line = lines[i].trim();
        if (line.charAt(0) !== '{') continue;
        try {
          const o = JSON.parse(line);
          if (o && typeof o.ok === 'boolean') {
            if (!o.data || typeof o.data !== 'object') o.data = {};
            return o;
          }
        } catch (e) {
          continue;
        }
      }
      return null;
    }

    function fail(code) {
      return { ok: false, code: code, message: FAIL[code] || FAIL.bridge, data: {} };
    }

    async function call(cmd, args) {
      const a = (args || []).map((x) => (x === null || x === undefined ? '' : String(x)));
      if (k) {
        let r;
        try {
          r = await exec(['sh', quote(MOD + '/sb.sh'), quote(cmd)].concat(a.map(quote)).join(' '));
        } catch (e) {
          return fail('bridge');
        }
        return parse(r.stdout) || fail('bridge');
      }
      if (framed) return fail('framed');
      if (!token) return fail('no_token');
      const p = new URLSearchParams();
      p.set('t', token);
      p.set('c', cmd);
      if (a.length > 0) p.set('a', a[0]);
      if (a.length > 1) p.set('b', a[1]);
      if (a.length > 2) p.set('d', a[2]);
      let res;
      try {
        res = await fetch('cgi-bin/api', {
          method: 'POST',
          cache: 'no-store',
          credentials: 'omit',
          referrerPolicy: 'no-referrer',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: p.toString()
        });
      } catch (e) {
        return fail('offline');
      }
      if (res.status === 403) return fail('unauthorized');
      let text = '';
      try {
        text = await res.text();
      } catch (e) {
        return fail('offline');
      }
      return parse(text) || fail(res.ok ? 'bridge' : 'offline');
    }

    return { call: call, mode: k ? 'ksu' : 'http', hasToken: () => !!token, framed: () => framed };
  })();

  async function api(cmd, args) {
    const r = await Bridge.call(cmd, args);
    if (!r.ok && (r.code === 'offline' || r.code === 'unauthorized' || r.code === 'no_token' || r.code === 'framed')) showGate(r.code);
    return r;
  }

  function toast(msg, kind) {
    if (!msg) return;
    const box = $('toasts');
    const t = h('div', { class: 'toast is-' + (kind || 'info'), role: 'status', text: msg });
    box.appendChild(t);
    while (box.children.length > 3) box.removeChild(box.firstChild);
    requestAnimationFrame(() => requestAnimationFrame(() => t.classList.add('is-in')));
    setTimeout(() => {
      t.classList.remove('is-in');
      setTimeout(() => {
        if (t.parentNode) t.parentNode.removeChild(t);
      }, 260);
    }, kind === 'err' ? 5600 : 3800);
  }

  const Modal = (() => {
    const root = $('modal');
    const sheet = $('sheet');
    const icon = $('sheet-icon');
    const title = $('sheet-title');
    const body = $('sheet-body');
    const actions = $('sheet-actions');
    let isOpen = false;
    let dismissible = true;
    let onDismiss = null;
    let closeTimer = 0;
    let lastFocus = null;
    let view = '';

    function render(v) {
      clear(icon);
      if (v.iconNode) icon.appendChild(v.iconNode);
      else icon.textContent = v.icon || '';
      title.textContent = v.title || '';
      clear(body);
      (v.body || []).forEach((n) => { if (n) body.appendChild(n); });
      body.classList.remove('is-swap');
      void body.offsetWidth;
      body.classList.add('is-swap');
      clear(actions);
      (v.actions || []).forEach((a) => {
        const b = h('button', { class: 'btn ' + (a.class || 'btn-ghost'), type: 'button', id: a.id || null });
        if (a.power) b.appendChild(powerIcon());
        b.appendChild(h('span', { class: 'btn-label', text: a.label }));
        if (a.disabled) b.disabled = true;
        b.addEventListener('click', a.onClick);
        actions.appendChild(b);
      });
      actions.hidden = !(v.actions && v.actions.length);
      dismissible = v.dismissible !== false;
      onDismiss = v.onDismiss || null;
      view = v.view || '';
      sheet.scrollTop = 0;
    }

    function show(v) {
      clearTimeout(closeTimer);
      render(v);
      if (!isOpen) {
        isOpen = true;
        lastFocus = document.activeElement;
        root.hidden = false;
        void root.offsetWidth;
        root.classList.add('is-open');
        document.body.classList.add('no-scroll');
        sheet.setAttribute('tabindex', '-1');
        try {
          sheet.focus({ preventScroll: true });
        } catch (e) {
          sheet.focus();
        }
      }
    }

    function close() {
      if (!isOpen) return;
      isOpen = false;
      view = '';
      root.classList.remove('is-open');
      document.body.classList.remove('no-scroll');
      closeTimer = setTimeout(() => { root.hidden = true; }, 270);
      if (lastFocus && typeof lastFocus.focus === 'function') {
        try {
          lastFocus.focus({ preventScroll: true });
        } catch (e) {
          lastFocus = null;
        }
      }
    }

    function dismiss() {
      if (!isOpen || !dismissible) return;
      const f = onDismiss;
      close();
      if (f) f();
    }

    function trap(e) {
      if (!isOpen || e.key !== 'Tab') return;
      const nodes = sheet.querySelectorAll('button:not([disabled]), input:not([disabled]), textarea:not([disabled])');
      if (!nodes.length) {
        e.preventDefault();
        return;
      }
      const first = nodes[0];
      const last = nodes[nodes.length - 1];
      const active = document.activeElement;
      if (e.shiftKey && (active === first || !sheet.contains(active))) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && (active === last || !sheet.contains(active))) {
        e.preventDefault();
        first.focus();
      }
    }

    $('modal-scrim').addEventListener('click', dismiss);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') dismiss();
      else trap(e);
    });

    return { show: show, close: close, open: () => isOpen, view: () => view };
  })();

  function gotIt() {
    return [{ label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }];
  }

  function confirmBox(o) {
    return new Promise((resolve) => {
      let done = false;
      const finish = (v) => {
        if (done) return;
        done = true;
        resolve(v);
      };
      Modal.show({
        icon: o.icon,
        iconNode: o.iconNode,
        title: o.title,
        body: o.body,
        view: 'confirm',
        onDismiss: () => finish(false),
        actions: [
          { label: '↩️ Not now', class: 'btn-ghost', onClick: () => { Modal.close(); finish(false); } },
          { label: o.ok, class: o.okClass || 'btn-primary', power: o.power, onClick: () => finish(true) }
        ]
      });
    });
  }

  function showGate(code) {
    if (S.gate === code) return;
    S.gate = code;
    const map = {
      no_token: ['🔑', 'Secure session required', 'Open StevenBlock from your root manager: tap the Action ▶️ button on the StevenBlock module card. It starts the local WebUI with a one-time secure link.'],
      unauthorized: ['🔑', 'Session expired', 'This WebUI session is no longer valid. Tap the Action ▶️ button on StevenBlock in your root manager to open a fresh one.'],
      offline: ['🔌', 'WebUI server stopped', 'The local server stops by itself after 10 minutes without activity. Tap the Action ▶️ button on StevenBlock in your root manager to start it again.'],
      framed: ['🚫', 'Blocked for your safety', 'StevenBlock never runs inside another page. Open it from the Action ▶️ button on the StevenBlock module card.'],
      bridge: ['❌', 'Couldn’t reach StevenBlock', 'The module didn’t answer. Make sure StevenBlock is installed and enabled — if you just installed it, reboot first.']
    };
    const m = map[code] || map.bridge;
    $('gate-icon').textContent = m[0];
    $('gate-title').textContent = m[1];
    $('gate-text').textContent = m[2];
    $('gate-retry').hidden = code === 'framed';
    Modal.close();
    $('gate').hidden = false;
  }

  async function retryGate() {
    const btn = $('gate-retry');
    btn.disabled = true;
    const code = S.gate;
    S.gate = '';
    const r = await Bridge.call('ping');
    btn.disabled = false;
    if (r.ok) {
      $('gate').hidden = true;
      if (!S.ready) {
        start();
      } else {
        refreshAll();
      }
    } else {
      showGate(r.code === 'bridge' ? (code || 'bridge') : r.code);
      toast(r.message, 'err');
    }
  }

  async function copyText(text) {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
        return true;
      }
    } catch (e) {
      return legacyCopy(text);
    }
    return legacyCopy(text);
  }

  function legacyCopy(text) {
    const ta = h('textarea', { class: 'area', readonly: true, 'aria-hidden': 'true' });
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    ta.style.pointerEvents = 'none';
    document.body.appendChild(ta);
    let ok = false;
    try {
      ta.focus();
      ta.select();
      ta.setSelectionRange(0, text.length);
      ok = document.execCommand('copy');
    } catch (e) {
      ok = false;
    }
    document.body.removeChild(ta);
    return ok;
  }

  function textSheet(o) {
    const ta = h('textarea', { class: 'area', readonly: true, spellcheck: 'false', 'aria-label': o.title });
    ta.value = o.text;
    const hint = h('p', { class: 'fine', text: o.hint || '' });
    Modal.show({
      icon: o.icon,
      title: o.title,
      body: [ta, hint],
      view: 'text',
      actions: [
        { label: '👌 Done', class: 'btn-ghost', onClick: () => Modal.close() },
        {
          label: '📋 Copy',
          class: 'btn-primary',
          onClick: async () => {
            const ok = await copyText(o.text);
            if (ok) {
              hint.textContent = '✅ Copied to the clipboard.';
              hint.className = 'fine is-ok';
            } else {
              ta.focus();
              ta.select();
              hint.textContent = '✏️ Copying isn’t available here. The text is selected — copy it by hand.';
              hint.className = 'fine';
            }
          }
        }
      ]
    });
  }

  function stateOf(st) {
    if (!st) return { cls: 'is-wait', e: '⏳', t: 'Loading…' };
    if (st.setup === 'pending') return { cls: 'is-wait', e: '⏳', t: 'Setup pending' };
    if (st.setup === 'failed') return { cls: 'is-off', e: '❌', t: 'Setup failed' };
    if (st.reboot) return { cls: 'is-warn', e: '🟡', t: 'Reboot required' };
    if (!st.enabled) return { cls: 'is-off', e: '🔴', t: 'Disabled' };
    if (st.applied === 'overridden') return { cls: 'is-warn', e: '⚠️', t: 'Overridden' };
    if (st.applied === 'inactive') return { cls: 'is-off', e: '🔴', t: 'Not active' };
    return { cls: 'is-on', e: '🟢', t: 'Active' };
  }

  function appliedText(a) {
    if (a === 'applied') return ['✅ Applied', 'is-ok'];
    if (a === 'pending') return ['🟡 Not applied yet — reboot required', 'is-warn'];
    if (a === 'overridden') return ['⚠️ Overridden by another module', 'is-warn'];
    if (a === 'inactive') return ['🔴 Not active — reboot to activate', 'is-err'];
    return ['ℹ️ The system hosts file couldn’t be checked', ''];
  }

  function staleDaysOf(st) {
    if (!st || st.setup !== 'ready' || !st.updated) return 0;
    return Math.floor((nowSec() - st.updated) / 86400);
  }

  function isStale(st) {
    return !!st && st.setup === 'ready' && st.enabled && staleDaysOf(st) >= (st.staleDays || 7);
  }

  function listName(id) {
    if (S.lists) {
      const all = (S.lists.lists || []).concat(S.lists.addons || []);
      for (let i = 0; i < all.length; i++) if (all[i].id === id) return all[i].name;
    }
    if (S.status && S.status.list === id) return S.status.listName;
    return id || 'your list';
  }

  function findList(id) {
    if (!S.lists || !S.lists.lists) return null;
    for (let i = 0; i < S.lists.lists.length; i++) if (S.lists.lists[i].id === id) return S.lists.lists[i];
    return null;
  }

  function findAddon(id) {
    if (!S.lists || !S.lists.addons) return null;
    for (let i = 0; i < S.lists.addons.length; i++) if (S.lists.addons[i].id === id) return S.lists.addons[i];
    return null;
  }

  function renderStatus() {
    const st = S.status;
    if (!st) return;
    const s = stateOf(st);
    const badge = $('badge');
    badge.className = 'badge ' + s.cls;
    $('badge-emoji').textContent = s.e;
    $('badge-text').textContent = s.t;
    $('ver').textContent = st.version || VERSION;
    $('credits-ver').textContent = 'StevenBlock ' + (st.version || VERSION) + ' • 🔒 Local only • No telemetry • Inter by Rasmus Andersson (SIL OFL 1.1)';

    const alert = $('ribbon-alert');
    const nav = $('ribbon-nav');
    let mode = '';
    if (st.reboot) mode = 'reboot';
    else if (st.setup !== 'ready' && !S.busy) mode = 'setup';
    else if (st.applied === 'inactive' && st.enabled && st.setup === 'ready') mode = 'inactive';
    if (mode) {
      const texts = {
        reboot: ['🟡 Reboot to apply changes', '🟡 Reboot required'],
        inactive: ['🔴 Reboot to activate', '🔴 Not active'],
        setup: st.setup === 'failed' ? ['❌ First download failed', '❌ Download failed'] : ['⏳ First list not downloaded', '⏳ Setup pending']
      };
      alert.classList.toggle('is-info', mode === 'setup');
      $('ribbon-long').textContent = texts[mode][0];
      $('ribbon-short').textContent = texts[mode][1];
      $('ribbon-btn').textContent = mode === 'setup' ? '⬇️ Download now' : '🔁 Reboot now';
      $('ribbon-btn').className = 'btn btn-xs ' + (mode === 'setup' ? 'btn-primary' : 'btn-warn');
      $('ribbon-btn').setAttribute('data-mode', mode);
      $('ribbon-btn').disabled = S.busy && mode === 'setup';
      alert.hidden = false;
      nav.hidden = true;
    } else {
      alert.hidden = true;
      nav.hidden = false;
    }

    const count = $('hero-count');
    clear(count);
    const sub = $('hero-sub');
    if (st.setup !== 'ready') {
      count.appendChild(h('span', { class: 'num is-muted', text: '—' }));
      sub.textContent = st.setup === 'failed' ? 'The first download failed — tap Download now to retry' : 'Waiting for the first download';
    } else if (!st.enabled) {
      count.appendChild(h('span', { class: 'num is-muted', text: 'Paused' }));
      sub.textContent = st.reboot ? 'Blocking turns off after the reboot' : 'Blocking is turned off';
    } else {
      count.appendChild(h('span', { class: 'num', text: fmtNum(st.domains) }));
      if (st.reboot) sub.textContent = 'domains ready — reboot to apply';
      else if (st.applied === 'overridden') sub.textContent = 'domains ready, but overridden';
      else if (st.applied === 'inactive') sub.textContent = 'domains ready — reboot to activate';
      else sub.textContent = 'domains blocked system-wide';
    }

    const addons = st.addons || [];
    const hl = clear($('hero-list'));
    hl.appendChild(h('span', { class: 'hl-name', text: '📋 ' + (st.listName || 'StevenBlack Main') }));
    hl.appendChild(h('span', { class: 'lvl lvl-' + (st.level || 'green'), text: (LEVEL[st.level] || '🟢') + ' ' + (st.levelText || '') }));
    if (addons.length) hl.appendChild(h('span', { class: 'hl-more', text: '➕ ' + addons.length + ' ' + plural(addons.length, 'add-on', 'add-ons') }));
    $('stat-rules').textContent = '✅ ' + fmtNum(st.allow) + '  ·  ⛔ ' + fmtNum(st.block);
    const upd = $('stat-updated');
    upd.textContent = st.setup === 'ready' ? ago(st.updated) : 'Not yet';
    upd.classList.toggle('is-stale', isStale(st));
    const ap = appliedText(st.applied);
    const apEl = $('hero-applied');
    apEl.textContent = ap[0];
    apEl.className = 'hero-applied ' + ap[1];

    const tags = clear($('hero-tags'));
    tags.appendChild(h('span', { class: 'fact', text: st.live ? '⚡ Live apply' : '🔁 Applies on reboot' }));
    tags.appendChild(h('span', { class: 'fact', text: '🔄 Auto-update: ' + (AUTO_TEXT[st.autoupdate] || 'Off') }));
    if (st.guard) tags.appendChild(h('span', { class: 'fact', text: '🔏 Private DNS protected' }));

    const tgl = $('act-toggle');
    tgl.classList.toggle('is-danger', !!st.enabled);
    tgl.classList.toggle('is-on', !st.enabled);
    $('toggle-label').textContent = st.enabled ? 'Disable Blocker' : 'Enable Blocker';
    let actNote = '🔄 Updates only download when a source list has changed.';
    if (!st.enabled) actNote = '🔴 The blocker is off. Enable it to switch or update lists.';
    else if (isStale(st)) actNote = '🕒 Your lists are ' + staleDaysOf(st) + ' days old. Tap Update Lists, or turn on auto-update in Settings.';
    $('actions-note').textContent = actNote;
    $('lists-note').textContent = st.enabled
      ? 'Pick a blocklist. Stronger lists block more, but can break more.'
      : '🔴 The blocker is off. Enable it in ⚡ Actions to switch or update lists.';
    applyBusy();
  }

  const cards = {};
  const rows = {};

  function makeCard(id) {
    const c = {};
    c.name = h('h3', { class: 'lc-name' });
    c.lvl = h('span', { class: 'lvl' });
    c.desc = h('p', { class: 'lc-desc' });
    c.count = h('span');
    c.date = h('span');
    c.retry = h('button', { class: 'btn btn-ghost btn-xs invisible', type: 'button', text: '🔁 Retry' });
    c.use = h('button', { class: 'btn btn-primary btn-xs', type: 'button', text: '⬇️ Use this list' });
    c.active = h('span', { class: 'lc-active', text: '✅ Active' });
    c.retry.addEventListener('click', () => refreshMeta(id));
    c.use.addEventListener('click', () => confirmApply(id));
    c.card = h('article', { class: 'lcard' },
      h('div', { class: 'lc-top' }, c.name, c.lvl),
      c.desc,
      h('div', { class: 'lc-meta' }, c.count, c.date),
      h('div', { class: 'lc-foot' }, c.retry, h('span', null, c.use, c.active))
    );
    return c;
  }

  function renderLists() {
    const L = S.lists;
    if (!L || !L.lists) return;
    const groups = { unified: $('group-unified'), hagezi: $('group-hagezi') };
    const fresh = {};
    L.lists.forEach((l) => {
      let c = cards[l.id];
      if (!c) {
        c = cards[l.id] = makeCard(l.id);
        fresh[l.group] = true;
      }
      updateCard(c, l);
    });
    Object.keys(fresh).forEach((g) => {
      const box = groups[g];
      if (!box) return;
      clear(box);
      L.lists.forEach((l) => { if (l.group === g) box.appendChild(cards[l.id].card); });
    });
    renderAddons();
  }

  function updateCard(c, l) {
    const L = S.lists;
    const st = S.status;
    c.name.textContent = l.name;
    c.lvl.className = 'lvl lvl-' + l.level;
    c.lvl.textContent = (LEVEL[l.level] || '') + ' ' + l.levelText;
    c.desc.textContent = l.desc;
    c.desc.title = l.desc;
    clear(c.count);
    clear(c.date);
    c.count.className = '';
    const hasCount = l.count !== null && l.count !== undefined;
    if (hasCount) {
      c.count.textContent = '🔢 ' + fmtNum(l.count) + ' entries';
      c.date.textContent = '📅 ' + (l.date ? fmtDate(l.date) : 'Unknown');
    } else if (l.busy || !l.error) {
      c.count.appendChild(sk('sk-line'));
      c.date.appendChild(sk('sk-line'));
    } else {
      c.count.textContent = '❌ Couldn’t fetch entry count';
      c.count.className = 'is-err';
      c.date.textContent = '📅 ' + (l.date ? fmtDate(l.date) : 'Unknown');
    }
    c.retry.classList.toggle('invisible', !(l.error && !l.busy));
    c.retry.disabled = !!l.busy;
    const isActive = !!(L && L.active === l.id && (!st || st.setup === 'ready'));
    c.card.classList.toggle('is-active', isActive);
    c.use.hidden = isActive;
    c.active.hidden = !isActive;
    const enabled = st ? st.enabled : (L ? L.enabled : true);
    c.use.disabled = S.busy || S.syncBusy || !enabled;
    c.use.title = !enabled ? 'Enable the blocker first' : '';
  }

  function activeAddonIds() {
    if (!S.lists || !S.lists.addons) return [];
    return S.lists.addons.filter((a) => a.enabled).map((a) => a.id);
  }

  function addonSelection() {
    return S.addonSel ? S.addonSel : activeAddonIds();
  }

  function sameIds(a, b) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) if (b.indexOf(a[i]) < 0) return false;
    return true;
  }

  function addonDiff() {
    const active = activeAddonIds();
    const sel = addonSelection();
    return {
      on: sel.filter((id) => active.indexOf(id) < 0),
      off: active.filter((id) => sel.indexOf(id) < 0)
    };
  }

  function addonsLocked() {
    const st = S.status;
    return S.busy || S.syncBusy || !st || !st.enabled || st.setup !== 'ready';
  }

  function makeRow(id) {
    const r = {};
    r.ico = h('span', { class: 'arow-ico', 'aria-hidden': 'true' });
    r.name = h('span', { class: 'arow-name' });
    r.top = h('div', { class: 'arow-top' }, r.name);
    r.desc = h('div', { class: 'arow-desc' });
    r.meta = h('div', { class: 'arow-meta' });
    r.sw = h('button', { class: 'switch', type: 'button', role: 'switch', 'aria-checked': 'false' });
    r.del = h('button', { class: 'rule-x', type: 'button', text: '🗑️', hidden: true });
    r.sw.addEventListener('click', () => toggleAddon(id));
    r.del.addEventListener('click', () => removeCustom(id));
    r.row = h('div', { class: 'arow' }, r.ico, h('div', { class: 'arow-text' }, r.top, r.desc, r.meta), h('div', { class: 'arow-side' }, r.del, r.sw));
    return r;
  }

  function updateRow(r, a) {
    const sel = addonSelection();
    const on = sel.indexOf(a.id) >= 0;
    r.ico.textContent = a.icon || '🧩';
    r.name.textContent = a.name;
    while (r.top.children.length > 1) r.top.removeChild(r.top.lastChild);
    if (a.suggested) r.top.appendChild(h('span', { class: 'tag tag-good', text: '✨ For your device' }));
    if (a.warn === 'heavy') r.top.appendChild(h('span', { class: 'tag tag-warn', text: '🐘 Large' }));
    if (a.warn === 'breaks') r.top.appendChild(h('span', { class: 'tag tag-warn', text: '⚠️ Strict' }));
    r.desc.textContent = a.desc;
    r.desc.title = a.desc;
    clear(r.meta);
    r.meta.className = 'arow-meta';
    const known = a.count !== null && a.count !== undefined ? a.count : a.installed;
    if (known !== null && known !== undefined) {
      let m = '🔢 ' + fmtNum(known) + ' ' + plural(known, 'entry', 'entries');
      if (a.enabled && a.added !== null && a.added !== undefined) m += '  ·  ➕ ' + fmtNum(a.added) + ' new';
      r.meta.textContent = m;
    } else if (a.error && !a.busy) {
      r.meta.textContent = '❌ Couldn’t fetch details';
      r.meta.className = 'arow-meta is-err';
    } else if (a.custom && !a.busy) {
      r.meta.textContent = a.enabled ? '🔢 Installed' : '🔢 Size shown after the first download';
    } else {
      r.meta.appendChild(sk('sk-line w-40'));
    }
    r.row.classList.toggle('is-on', on);
    r.row.classList.toggle('is-changed', on !== !!a.enabled);
    r.sw.setAttribute('aria-checked', on ? 'true' : 'false');
    r.sw.setAttribute('aria-label', (on ? 'Turn off ' : 'Turn on ') + a.name);
    r.sw.disabled = addonsLocked();
    r.del.hidden = !a.custom;
    r.del.disabled = S.busy || S.syncBusy;
    r.del.setAttribute('aria-label', 'Remove ' + a.name);
  }

  function renderAddons() {
    const L = S.lists;
    if (!L || !L.addons) return;
    const box = $('addons');
    const ids = L.addons.map((a) => a.id);
    if (S.addonSel) {
      const kept = S.addonSel.filter((id) => ids.indexOf(id) >= 0);
      S.addonSel = sameIds(kept, activeAddonIds()) ? null : kept;
    }
    Object.keys(rows).forEach((id) => { if (ids.indexOf(id) < 0) delete rows[id]; });
    const sig = ids.join(',');
    if (box.getAttribute('data-sig') !== sig) {
      clear(box);
      ADDON_GROUPS.forEach((g) => {
        const items = L.addons.filter((a) => a.group === g[0]);
        if (!items.length && g[0] !== 'custom') return;
        const head = h('div', { class: 'agroup' }, h('span', { text: g[1] }));
        if (g[0] === 'custom') {
          const add = h('button', { class: 'btn btn-ghost btn-xs', type: 'button', id: 'custom-add', text: '➕ Add a list' });
          add.addEventListener('click', addCustomFlow);
          head.appendChild(add);
        }
        box.appendChild(head);
        if (!items.length) box.appendChild(h('div', { class: 'empty', text: '🌱 Add any HTTPS hosts or domain list by its address.' }));
        items.forEach((a) => {
          if (!rows[a.id]) rows[a.id] = makeRow(a.id);
          box.appendChild(rows[a.id].row);
        });
      });
      box.setAttribute('data-sig', sig);
    }
    L.addons.forEach((a) => { if (rows[a.id]) updateRow(rows[a.id], a); });
    const add = $('custom-add');
    if (add) add.disabled = S.busy || S.syncBusy || L.addons.filter((a) => a.custom).length >= (L.customMax || 8);
    renderAddonBar();
  }

  function renderAddonBar() {
    const d = addonDiff();
    const n = d.on.length + d.off.length;
    const bar = $('addon-bar');
    bar.hidden = n === 0;
    $('addon-bar-text').textContent = '🧩 ' + n + ' ' + plural(n, 'change', 'changes');
    $('addon-apply').disabled = addonsLocked();
    $('addon-reset').disabled = S.busy || S.syncBusy;
  }

  function toggleAddon(id) {
    if (addonsLocked()) {
      const st = S.status;
      if (st && !st.enabled) toast('🔴 Enable the blocker first.', 'warn');
      else if (st && st.setup !== 'ready') toast('⏳ Download your main list first.', 'warn');
      return;
    }
    const sel = addonSelection().slice();
    const i = sel.indexOf(id);
    if (i >= 0) sel.splice(i, 1);
    else sel.push(id);
    S.addonSel = sameIds(sel, activeAddonIds()) ? null : sel;
    renderAddons();
  }

  function resetAddons() {
    S.addonSel = null;
    renderAddons();
  }

  function renderRules() {
    const R = S.rules;
    $('count-allow').textContent = String(R.allow.length);
    $('count-block').textContent = String(R.block.length);
    const ta = $('tab-allow');
    const tb = $('tab-block');
    ta.classList.toggle('is-on', S.tab === 'allow');
    tb.classList.toggle('is-on', S.tab === 'block');
    ta.setAttribute('aria-selected', S.tab === 'allow' ? 'true' : 'false');
    tb.setAttribute('aria-selected', S.tab === 'block' ? 'true' : 'false');
    const ul = clear($('rule-list'));
    const all = R[S.tab] || [];
    const wrap = $('rule-filter-wrap');
    wrap.hidden = all.length <= 8 && !S.ruleFilter;
    const q = S.ruleFilter.trim().toLowerCase();
    const list = q ? all.filter((d) => d.indexOf(q) >= 0) : all;
    if (!all.length) {
      ul.appendChild(h('li', { class: 'empty', text: S.tab === 'allow' ? '🌱 No allow rules yet. Add a domain above to always let it through.' : '🌱 No block rules yet. Add a domain above to always block it.' }));
      return;
    }
    if (!list.length) {
      ul.appendChild(h('li', { class: 'empty', text: '🔎 No rule matches “' + q + '”.' }));
      return;
    }
    const type = S.tab;
    const frag = document.createDocumentFragment();
    list.slice().reverse().forEach((d) => {
      const x = h('button', { class: 'rule-x', type: 'button', 'aria-label': 'Remove ' + d, text: '🗑️' });
      x.disabled = S.busy || S.syncBusy;
      x.addEventListener('click', () => deleteRule(type, d, x));
      frag.appendChild(h('li', { class: 'rule' }, h('span', { class: 'rule-d', text: (type === 'allow' ? '✅ ' : '⛔ ') + d }), x));
    });
    ul.appendChild(frag);
  }

  function visibleLogs() {
    const logs = S.logs || [];
    if (S.logLevel === 'error') return logs.filter((l) => l.l === 'ERROR');
    if (S.logLevel === 'warn') return logs.filter((l) => l.l === 'ERROR' || l.l === 'WARN');
    return logs;
  }

  function renderLogs() {
    const box = $('logbox');
    const logs = visibleLogs();
    const last = logs.length ? logs[logs.length - 1] : null;
    const sig = S.logLevel + '|' + logs.length + '|' + (last ? last.t + last.m : '');
    if (sig === S.logSig) return;
    const first = S.logSig === '' || S.logSig.split('|')[0] !== S.logLevel;
    S.logSig = sig;
    const nearBottom = box.scrollHeight - box.scrollTop - box.clientHeight < 48;
    clear(box);
    if (!logs.length) {
      const empty = { all: '📭 No log entries yet.', warn: '✅ No warnings or errors.', error: '✅ No errors.' };
      box.appendChild(h('div', { class: 'empty', text: empty[S.logLevel] || empty.all }));
      return;
    }
    const frag = document.createDocumentFragment();
    logs.forEach((l) => {
      const lvl = l.l === 'ERROR' ? ['is-error', '❌ ERROR'] : (l.l === 'WARN' ? ['is-warn', '⚠️ WARN'] : ['is-info', 'ℹ️ INFO']);
      frag.appendChild(h('div', { class: 'log ' + lvl[0] },
        h('span', { class: 'log-t', text: logTime(l.t) }),
        h('span', { class: 'log-l', text: lvl[1] }),
        h('span', { class: 'log-m', text: l.m })
      ));
    });
    box.appendChild(frag);
    if (first || nearBottom) box.scrollTop = box.scrollHeight;
  }

  function setLogLevel(level) {
    S.logLevel = level;
    const fs = document.querySelectorAll('.filter');
    for (let i = 0; i < fs.length; i++) {
      const on = fs[i].getAttribute('data-level') === level;
      fs[i].classList.toggle('is-on', on);
      fs[i].setAttribute('aria-selected', on ? 'true' : 'false');
    }
    renderLogs();
  }

  function applyBusy() {
    const st = S.status;
    const busy = S.busy || S.syncBusy;
    const enabled = st ? !!st.enabled : true;
    $('act-update').disabled = busy || !enabled || !st;
    $('act-toggle').disabled = busy || !st;
    $('act-repair').disabled = busy || !st;
    $('act-settings').disabled = !st;
    $('rule-allow').disabled = busy;
    $('rule-block').disabled = busy;
    $('rules-import').disabled = busy;
    $('logs-clear').disabled = false;
    Object.keys(cards).forEach((id) => {
      cards[id].use.disabled = busy || !enabled;
    });
    Object.keys(rows).forEach((id) => {
      rows[id].sw.disabled = addonsLocked();
      rows[id].del.disabled = busy;
    });
    const add = $('custom-add');
    if (add && busy) add.disabled = true;
    renderAddonBar();
    const xs = document.querySelectorAll('#rule-list .rule-x');
    for (let i = 0; i < xs.length; i++) xs[i].disabled = busy;
    const lk = document.querySelectorAll('#lookup .btn');
    for (let i = 0; i < lk.length; i++) lk[i].disabled = busy;
    if (st) {
      const rb = $('ribbon-btn');
      if (rb.getAttribute('data-mode') === 'setup') rb.disabled = busy;
    }
  }

  const PV = { built: false };

  function buildProgress() {
    PV.steps = STEPS.map((s) => h('div', { class: 'step' }, h('span', { class: 'step-e', text: s[1] }), h('span', { text: s[2] })));
    PV.phase = h('span');
    PV.pct = h('span', { class: 'pg-pct' });
    PV.fill = h('div', { class: 'bar-fill' });
    PV.bar = h('div', { class: 'bar is-indet' }, PV.fill, h('div', { class: 'bar-stripes' }));
    PV.left = h('span');
    PV.right = h('span');
    PV.root = h('div', { class: 'prog' },
      h('div', { class: 'steps' }, PV.steps),
      h('div', { class: 'pg-phase' }, PV.phase, PV.pct),
      PV.bar,
      h('div', { class: 'pg-meta' }, PV.left, PV.right)
    );
    PV.built = true;
  }

  function opTitle(op) {
    const name = listName(op.list);
    if (op.kind === 'update' || op.kind === 'auto') return 'Updating your lists';
    if (op.kind === 'enable') return 'Turning blocking back on';
    if (op.kind === 'addons') return 'Applying add-ons';
    if (op.kind === 'setup') return 'Downloading ' + name;
    return 'Installing ' + name;
  }

  function opIcon(op) {
    if (op.kind === 'update' || op.kind === 'auto') return '🔄';
    if (op.kind === 'addons') return '🧩';
    return '⬇️';
  }

  function showProgress(op) {
    if (Modal.view() !== 'progress' || !Modal.open()) {
      buildProgress();
      Modal.show({
        icon: opIcon(op),
        title: opTitle(op),
        body: [PV.root],
        view: 'progress',
        onDismiss: hideProgress,
        actions: [
          { label: '✖️ Cancel', class: 'btn-ghost', id: 'pg-cancel', onClick: cancelOp },
          { label: '🔽 Hide', class: 'btn-ghost', onClick: hideProgress }
        ]
      });
    }
    hideMini();
    updateProgress(op);
  }

  function trackSpeed(op) {
    const sp = S.speed;
    const now = performance.now();
    if (!op.running || op.phase !== 'download') {
      sp.t = 0;
      sp.b = 0;
      return sp.v;
    }
    if (!sp.t || op.bytes < sp.b) {
      sp.t = now;
      sp.b = op.bytes;
      sp.v = 0;
      return 0;
    }
    if (now - sp.t >= 300) {
      const inst = (op.bytes - sp.b) / ((now - sp.t) / 1000);
      sp.v = sp.v ? sp.v * 0.6 + inst * 0.4 : inst;
      sp.t = now;
      sp.b = op.bytes;
    }
    return sp.v;
  }

  function progressNumbers(op) {
    const order = { prepare: -1, check: -1, download: 0, verify: 1, optimize: 2, install: 3, finish: 4 };
    const idx = order[op.phase] === undefined ? -1 : order[op.phase];
    const total = Number(op.total) || 0;
    const bytes = Number(op.bytes) || 0;
    let ratio = -1;
    if (op.phase === 'download' && total > 0) ratio = Math.min(1, bytes / total);
    return { idx: idx, total: total, bytes: bytes, ratio: ratio };
  }

  function phaseLine(op) {
    if (op.cancelling) return '✖️ Cancelling…';
    const base = PHASE_TEXT[op.phase] || PHASE_TEXT.prepare;
    const fetching = op.phase === 'check' || op.phase === 'download' || op.phase === 'verify' || op.phase === 'optimize';
    if (!fetching || !op.sourceName) return base;
    const verb = { check: '🔎 Checking', download: '⬇️ Downloading', verify: '🔍 Verifying', optimize: '🧹 Optimizing' }[op.phase];
    let line = verb + ' ' + op.sourceName;
    if (op.items > 1 && op.item > 0) line += ' (' + op.item + ' of ' + op.items + ')';
    return line + '…';
  }

  function updateProgress(op) {
    if (!PV.built) return;
    const n = progressNumbers(op);
    const speed = trackSpeed(op);
    PV.steps.forEach((el, i) => {
      el.classList.toggle('is-done', i < n.idx);
      el.classList.toggle('is-active', i === n.idx);
    });
    PV.phase.textContent = phaseLine(op);
    if (n.ratio >= 0) {
      PV.bar.classList.remove('is-indet');
      PV.fill.style.transform = 'scaleX(' + n.ratio.toFixed(4) + ')';
      PV.pct.textContent = Math.floor(n.ratio * 100) + '%';
    } else {
      PV.bar.classList.add('is-indet');
      PV.fill.style.transform = 'scaleX(' + (n.idx > 0 ? 1 : 0) + ')';
      PV.pct.textContent = '';
    }
    if (op.phase === 'download') {
      PV.left.textContent = n.total > 0 ? fmtMB(n.bytes) + ' of ' + fmtMB(n.total) : fmtMB(n.bytes) + ' downloaded';
      PV.right.textContent = speed > 0 ? fmtMB(speed) + '/s' : '';
    } else if (n.idx > 0) {
      PV.left.textContent = n.total > 0 ? '✅ Downloaded ' + fmtMB(n.total) : '✅ Download complete';
      PV.right.textContent = '';
    } else {
      PV.left.textContent = op.phase === 'check' ? 'Comparing with the source…' : 'Getting ready…';
      PV.right.textContent = '';
    }
    const cancel = $('pg-cancel');
    if (cancel) {
      cancel.disabled = !op.cancellable || !!op.cancelling;
      const lab = cancel.querySelector('.btn-label') || cancel;
      lab.textContent = op.cancelling ? '✖️ Cancelling…' : '✖️ Cancel';
    }
    updateMini(op);
  }

  function hideProgress() {
    S.opView = false;
    if (Modal.view() === 'progress') Modal.close();
    if (S.op && S.op.running) showMini(S.op);
  }

  function showMini(op) {
    const m = $('mini');
    m.hidden = false;
    document.body.classList.add('has-mini');
    updateMini(op);
  }

  function hideMini() {
    $('mini').hidden = true;
    document.body.classList.remove('has-mini');
  }

  function updateMini(op) {
    const m = $('mini');
    if (m.hidden) return;
    const n = progressNumbers(op);
    let text = phaseLine(op).replace('…', '');
    if (!op.sourceName) text += ' • ' + listName(op.list);
    if (n.ratio >= 0) text += ' • ' + Math.floor(n.ratio * 100) + '%';
    $('mini-text').textContent = text;
    const r = n.ratio >= 0 ? n.ratio : (n.idx >= 0 ? (n.idx + 1) / 5 : 0.05);
    $('mini-fill').style.transform = 'scaleX(' + r.toFixed(4) + ')';
  }

  let pollTimer = 0;
  let polling = false;

  function schedulePoll(ms) {
    clearTimeout(pollTimer);
    pollTimer = setTimeout(pollOp, ms);
  }

  async function pollOp() {
    if (polling) return;
    polling = true;
    const r = await api('progress');
    polling = false;
    if (r.ok) handleOp(r.data);
    if (S.op && S.op.running) schedulePoll(document.hidden ? 2000 : 400);
  }

  function markSeen(seq) {
    if (seq > S.seen) {
      S.seen = seq;
      store.set('sb-seq', String(seq));
    }
  }

  function handleOp(op) {
    if (!op || typeof op !== 'object') return;
    const wasBusy = S.busy;
    S.op = op;
    if (op.running) {
      S.busy = true;
      if (!wasBusy && !S.opView && Modal.view() !== 'progress' && !Modal.open() && op.kind !== 'auto') S.opView = true;
      if (S.opView) showProgress(op);
      else {
        if (Modal.view() !== 'progress') showMini(op);
        updateMini(op);
      }
      applyBusy();
      if (!pollTimer || !wasBusy) schedulePoll(400);
      return;
    }
    S.busy = false;
    S.speed = { t: 0, b: 0, v: 0 };
    hideMini();
    applyBusy();
    const finished = op.seq && op.seq > S.seen && op.state && op.state !== 'idle';
    if (!finished) {
      if (Modal.view() === 'progress') Modal.close();
      S.opView = false;
      return;
    }
    const recent = wasBusy || (op.ended && nowSec() - op.ended < 600);
    markSeen(op.seq);
    if (!recent) return;
    S.addonSel = null;
    if (S.opView || Modal.view() === 'progress') showResult(op);
    else if (op.kind !== 'auto' || op.code !== 'up_to_date') toast(op.message, op.state === 'success' ? 'ok' : (op.state === 'cancelled' ? 'info' : 'err'));
    S.opView = false;
    refreshAll();
  }

  function showResult(op) {
    const msg = stripLead(op.message);
    let icon = '✅';
    let title = 'Done';
    let actions = gotIt();
    const body = [para(msg, 'center')];
    if (op.state === 'success') {
      if (op.code === 'up_to_date') title = 'Already up to date';
      else if (op.code === 'unchanged') title = 'Nothing to change';
      else if (op.kind === 'update' || op.kind === 'auto') title = 'Lists updated';
      else if (op.kind === 'addons') title = 'Add-ons applied';
      else title = 'Ready to go';
      if (op.reboot) {
        body.push(note('💡 No rush — your current protection keeps working until you reboot.', 'warn'));
        actions = [
          { label: '⏰ Later', class: 'btn-ghost', onClick: () => Modal.close() },
          { label: '🔁 Reboot now', class: 'btn-warn', onClick: rebootFlow }
        ];
      } else if (op.live) {
        body.push(note('⚡ Applied live. Apps that were already open may need a restart to notice.'));
      }
    } else if (op.state === 'cancelled') {
      icon = '✖️';
      title = 'Cancelled';
    } else {
      icon = '❌';
      const t = { apply: 'Couldn’t switch lists', update: 'Update failed', auto: 'Update failed', enable: 'Couldn’t enable blocking', setup: 'Download failed', addons: 'Couldn’t apply add-ons' };
      title = t[op.kind] || 'Something went wrong';
      if (!/nothing was changed|restored|intact/i.test(op.message || '')) body.push(note('🛟 Nothing was lost — your previous hosts file is still in place.', 'err'));
      if (op.kind === 'apply' || op.kind === 'update' || op.kind === 'setup' || op.kind === 'enable') {
        actions = [
          { label: '👌 Got it', class: 'btn-ghost', onClick: () => Modal.close() },
          { label: '🔁 Try again', class: 'btn-primary', onClick: () => retryOp(op) }
        ];
      }
    }
    Modal.show({ icon: icon, title: title, body: body, actions: actions, view: 'result' });
  }

  function retryOp(op) {
    if (op.kind === 'update' || op.kind === 'setup') return runUpdate();
    if (op.kind === 'enable') return toggleBlocker();
    return startApply(op.list);
  }

  function showReplyError(r, kind) {
    S.opView = false;
    const t = { apply: 'Couldn’t switch lists', update: 'Couldn’t start the update', enable: 'Couldn’t enable blocking', addons: 'Couldn’t apply add-ons', source: 'Couldn’t add the list' };
    if (r.code === 'offline' || r.code === 'unauthorized' || r.code === 'no_token' || r.code === 'framed') {
      Modal.close();
      return;
    }
    Modal.show({
      icon: r.code === 'busy' ? '⏳' : (r.code === 'already_active' ? '⚠️' : '❌'),
      title: r.code === 'busy' ? 'Please wait' : (r.code === 'already_active' ? 'Already active' : (t[kind] || 'Something went wrong')),
      body: [para(stripLead(r.message), 'center')],
      view: 'result',
      actions: gotIt()
    });
  }

  function resetSpeed() {
    S.speed = { t: 0, b: 0, v: 0 };
  }

  async function confirmApply(id) {
    const l = findList(id);
    const st = S.status;
    if (!l || !st || S.busy) return;
    if (!st.enabled) {
      toast('🔴 Enable the blocker first.', 'warn');
      return;
    }
    const facts = [];
    if (l.count) facts.push(h('span', { class: 'fact', text: '🔢 ~' + fmtNum(l.count) + ' entries' }));
    if (l.size) facts.push(h('span', { class: 'fact', text: '⬇️ ~' + fmtMB(l.size) }));
    if (l.date) facts.push(h('span', { class: 'fact', text: '📅 ' + fmtDate(l.date) }));
    const body = [
      h('div', { class: 'facts facts-top' }, h('span', { class: 'lvl lvl-' + l.level, text: (LEVEL[l.level] || '') + ' ' + l.levelText })),
      para(l.desc, 'center')
    ];
    if (facts.length) body.push(h('div', { class: 'facts' }, facts));
    if (l.level === 'orange' || l.level === 'red') {
      body.push(note('⚠️ This is a strict list. Some sites or app features may stop working — you can always allow a domain in 🧩 Domain Rules.', 'warn'));
    }
    const kept = (st.addons || []).length;
    body.push(note((st.live ? '⚡ It takes effect right away whenever your device allows it.' : '🔁 A reboot is needed to activate it.') + ' Your domain rules' + (kept ? ' and add-ons' : '') + ' are kept.'));
    const ok = await confirmBox({ icon: '📋', title: 'Switch to ' + l.name + '?', body: body, ok: '⬇️ Apply list' });
    if (!ok) return;
    startApply(id);
  }

  async function startJob(kind, cmd, args, first) {
    S.opView = true;
    resetSpeed();
    showProgress(Object.assign({ running: true, kind: kind, phase: 'prepare', bytes: 0, total: 0, cancellable: false }, first || {}));
    const r = await api(cmd, args);
    if (!r.ok || r.code !== 'started') {
      if (r.ok) {
        S.opView = false;
        Modal.close();
        toast(r.message, 'ok');
        refreshAll();
      } else {
        showReplyError(r, kind);
      }
      return r;
    }
    handleOp(r.data.op);
    schedulePoll(400);
    return r;
  }

  function startApply(id) {
    return startJob('apply', 'apply', [id], { list: id });
  }

  function runUpdate() {
    const st = S.status;
    if (!st || !st.enabled || S.busy) return null;
    const ready = st.setup === 'ready';
    return startJob(ready ? 'update' : 'setup', 'update', [], { list: st.list, phase: ready ? 'check' : 'prepare' });
  }

  async function applyAddons() {
    if (addonsLocked()) return;
    const d = addonDiff();
    if (!d.on.length && !d.off.length) return;
    const items = [];
    let extra = 0;
    const warns = [];
    d.on.forEach((id) => {
      const a = findAddon(id);
      if (!a) return;
      items.push(h('li', { text: '➕ ' + (a.icon ? a.icon + ' ' : '') + a.name + (a.count ? ' · ~' + fmtNum(a.count) + ' entries' : '') }));
      extra += Number(a.count) || 0;
      if (a.warn && ADDON_WARN[a.warn] && warns.indexOf(ADDON_WARN[a.warn]) < 0) warns.push(ADDON_WARN[a.warn]);
    });
    d.off.forEach((id) => {
      const a = findAddon(id);
      if (a) items.push(h('li', { text: '➖ ' + (a.icon ? a.icon + ' ' : '') + a.name }));
    });
    const body = [h('ul', { class: 'change-list' }, items)];
    warns.forEach((w) => body.push(note(w, 'warn')));
    if (extra > 0) body.push(note('🧮 Up to ' + fmtNum(extra) + ' more entries. Domains your lists already block are only counted once.'));
    const ok = await confirmBox({ icon: '🧩', title: 'Apply add-on changes?', body: body, ok: '✅ Apply' });
    if (!ok) return;
    const sel = addonSelection().slice();
    await startJob('addons', 'addons', [sel.join(',')], { list: S.status ? S.status.list : '' });
  }

  function checkUrl(raw) {
    const s = String(raw || '').trim();
    if (!s) return { err: '✏️ Enter the address of a list first.' };
    if (!/^https:\/\//i.test(s)) return { err: '🚫 Enter a full HTTPS address, like https://example.com/hosts.txt' };
    if (s.length > 300) return { err: '🚫 That address is too long.' };
    if (/[^A-Za-z0-9._~:/?&=%+,@-]/.test(s)) return { err: '🚫 That address contains characters that aren’t allowed.' };
    return { url: 'https://' + s.slice(8) };
  }

  function addCustomFlow() {
    if (S.busy || S.syncBusy) return;
    const url = h('input', { type: 'text', inputmode: 'url', autocomplete: 'off', autocapitalize: 'off', autocorrect: 'off', spellcheck: 'false', maxlength: '300', placeholder: 'https://example.com/hosts.txt', 'aria-label': 'List address' });
    const name = h('input', { type: 'text', autocomplete: 'off', maxlength: '40', placeholder: 'Name (optional)', 'aria-label': 'List name' });
    const msg = h('p', { class: 'fine', text: 'Hosts files, plain domain lists and simple ||domain^ lists are understood.' });
    const submit = async () => {
      const c = checkUrl(url.value);
      if (c.err) {
        msg.textContent = c.err;
        msg.className = 'fine is-err';
        return;
      }
      await startJob('source', 'source-add', [c.url, name.value.trim()], { kind: 'addons', list: S.status ? S.status.list : '' });
    };
    url.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); name.focus(); } });
    name.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); submit(); } });
    Modal.show({
      icon: '🔗',
      title: 'Add your own list',
      body: [
        h('label', { class: 'field' }, url),
        h('label', { class: 'field' }, name),
        msg,
        note('🛡️ Whatever a list contains, StevenBlock only ever turns its entries into blocks. A list can’t redirect a domain somewhere else.')
      ],
      view: 'custom',
      actions: [
        { label: '↩️ Not now', class: 'btn-ghost', onClick: () => Modal.close() },
        { label: '➕ Add list', class: 'btn-primary', onClick: submit }
      ]
    });
    setTimeout(() => {
      try {
        url.focus({ preventScroll: true });
      } catch (e) {
        url.focus();
      }
    }, 280);
  }

  async function removeCustom(id) {
    const a = findAddon(id);
    if (!a || S.busy || S.syncBusy) return;
    const ok = await confirmBox({
      icon: '🗑️',
      title: 'Remove ' + a.name + '?',
      body: [para('The list is removed from StevenBlock' + (a.enabled ? ' and its entries stop being blocked.' : '.'), 'center')],
      ok: '🗑️ Remove',
      okClass: 'btn-danger'
    });
    if (!ok) return;
    Modal.close();
    setSyncBusy(true);
    const r = await api('source-del', [id]);
    setSyncBusy(false);
    toast(r.message, r.ok ? 'ok' : 'err');
    S.addonSel = null;
    refreshAll();
  }

  async function cancelOp() {
    const btn = $('pg-cancel');
    if (btn) btn.disabled = true;
    const r = await api('cancel');
    if (r.ok) {
      if (S.op) {
        S.op.cancelling = true;
        updateProgress(S.op);
      }
    } else {
      toast(r.message, 'warn');
      if (btn && S.op) btn.disabled = !S.op.cancellable;
    }
  }

  async function toggleBlocker() {
    const st = S.status;
    if (!st || S.busy || S.syncBusy) return;
    if (st.enabled) {
      const ok = await confirmBox({
        iconNode: powerIcon(),
        title: 'Disable StevenBlock?',
        body: [para('Ads and trackers won’t be blocked ' + (st.live ? 'from now on' : 'after the next reboot') + '. Your lists and domain rules are kept, so you can turn it back on anytime.', 'center')],
        ok: 'Disable',
        okClass: 'btn-danger',
        power: true
      });
      if (!ok) return;
      Modal.close();
      setSyncBusy(true);
      const r = await api('disable');
      setSyncBusy(false);
      toast(r.message, r.ok ? 'warn' : 'err');
      refreshAll();
      return;
    }
    setSyncBusy(true);
    const r = await api('enable');
    setSyncBusy(false);
    if (r.ok && r.code === 'started') {
      S.opView = true;
      handleOp(r.data.op);
      schedulePoll(400);
    } else {
      toast(r.message, r.ok ? 'ok' : 'err');
    }
    refreshAll();
  }

  function setSyncBusy(v) {
    S.syncBusy = v;
    applyBusy();
  }

  async function rebootFlow() {
    const ok = await confirmBox({
      icon: '🔁',
      title: 'Reboot now?',
      body: [para('Your device restarts to apply the new hosts file. Save your work in other apps first.', 'center')],
      ok: '🔁 Reboot',
      okClass: 'btn-warn'
    });
    if (!ok) return;
    const r = await api('reboot');
    if (r.ok) {
      Modal.show({ icon: '🔁', title: 'Rebooting…', body: [para('See you in a moment. Your new settings are active after the restart.', 'center')], actions: [], dismissible: false, view: 'reboot' });
    } else {
      Modal.show({ icon: '❌', title: 'Couldn’t reboot', body: [para(stripLead(r.message), 'center')], view: 'result', actions: gotIt() });
    }
  }

  function statusRows(st) {
    const addons = st.addons || [];
    const mounts = { manager: 'Root manager', self: 'StevenBlock (direct)', conflict: 'Another module', failed: '❌ Mount failed' };
    return [
      ['🛡️ Blocker', st.enabled ? '🟢 On' : '🔴 Off'],
      ['📋 Active list', st.listName || '—'],
      ['🎚️ Level', (LEVEL[st.level] || '') + ' ' + (st.levelText || '')],
      ['➕ Add-ons', addons.length ? addons.map((a) => a.name).join(', ') : 'None'],
      ['🔢 Domains blocked', st.setup === 'ready' ? (st.enabled ? fmtNum(st.domains) : '0 (paused)') : '—'],
      ['✅ Allow rules', fmtNum(st.allow) + (st.stats && st.stats.allowed ? ' · unblocking ' + fmtNum(st.stats.allowed) : '')],
      ['⛔ Block rules', fmtNum(st.block)],
      ['🕒 Last update', st.updated && st.setup === 'ready' ? stampFmt.format(new Date(st.updated * 1000)) + ' · ' + ago(st.updated) : 'Never'],
      ['🔄 Auto-update', (AUTO_TEXT[st.autoupdate] || 'Off') + (st.autoupdate ? (st.sched ? ' · running' : ' · starts at boot') : '')],
      ['⚡ Live apply', st.live ? 'On' : 'Off'],
      ['🔁 Reboot pending', st.reboot ? '🟡 Yes' : 'No'],
      ['🧪 Applied', appliedText(st.applied)[0]],
      ['🔗 Mounted by', mounts[st.mount] || '—'],
      ['🔏 Private DNS', st.guard ? st.guard + ' (protected)' : 'No provider hostname set'],
      ['🧾 Hosts file', fmtMB(st.hostsSize)],
      ['🧰 Root manager', (st.manager || 'Unknown') + (st.managerVersion ? ' ' + st.managerVersion : '')],
      ['📦 Module version', (st.version || VERSION) + ' (' + (st.versionCode || VERSION_CODE) + ')'],
      ['🖥️ Interface', Bridge.mode === 'ksu' ? 'Root manager WebUI' : 'Local server · 127.0.0.1:9090']
    ];
  }

  async function showStatusDialog() {
    const btn = $('act-status');
    btn.disabled = true;
    const r = await api('status');
    btn.disabled = false;
    if (!r.ok) {
      toast(r.message, 'err');
      return;
    }
    S.status = r.data;
    renderStatus();
    const st = r.data;
    const list = h('div', { class: 'kv-list' }, statusRows(st).map((row) => h('div', { class: 'kv' }, h('span', { class: 'k', text: row[0] }), h('span', { class: 'v', text: row[1] }))));
    const body = [list];
    if (st.conflicts && st.conflicts.length) {
      const names = st.conflicts.map((c) => (c === 'hosts' ? 'Systemless hosts' : c)).join(', ');
      body.push(note('⚠️ These modules also replace /system/etc/hosts: ' + names + '. Disable them so StevenBlock can work.', 'warn'));
    }
    if (st.adaway) body.push(note('⚠️ AdAway is installed. Don’t use its root or systemless mode together with StevenBlock.', 'warn'));
    if (st.applied === 'pending') body.push(note('🔁 Your latest changes are saved and become active after a reboot.'));
    if (st.applied === 'inactive') {
      body.push(note(st.mount === 'failed'
        ? '🔴 Android isn’t using StevenBlock’s hosts file, and mounting it at startup failed. Check 📜 Logs for details.'
        : '🔴 Android isn’t using StevenBlock’s hosts file yet. Reboot — StevenBlock mounts it automatically at startup.', 'err'));
    }
    if (st.applied === 'applied' && st.mount === 'self') body.push(note('🔗 Your root manager didn’t mount the hosts file, so StevenBlock mounted it directly. Blocking works normally.'));
    Modal.show({ icon: '📊', title: 'Status', body: body, view: 'status', actions: gotIt() });
  }

  function switchRow(name, desc, on, onToggle) {
    const sw = h('button', { class: 'switch', type: 'button', role: 'switch', 'aria-checked': on ? 'true' : 'false', 'aria-label': name });
    sw.addEventListener('click', () => onToggle(sw));
    return h('div', { class: 'set-row' }, h('div', { class: 'set-text' }, h('div', { class: 'set-name', text: name }), h('div', { class: 'set-desc', text: desc })), sw);
  }

  async function saveSetting(key, value) {
    const r = await api('set', [key, String(value)]);
    toast(r.message, r.ok ? 'ok' : 'err');
    await loadStatus();
    return r;
  }

  function showSettings() {
    const st = S.status;
    if (!st) return;
    const live = switchRow('⚡ Live apply', 'Write changes straight into the mounted hosts file so they work without a reboot. Turn it off to keep the classic behaviour: swap the file and reboot.', !!st.live, async (sw) => {
      const next = sw.getAttribute('aria-checked') !== 'true';
      sw.disabled = true;
      const r = await saveSetting('live', next ? 1 : 0);
      sw.disabled = false;
      if (r.ok) sw.setAttribute('aria-checked', next ? 'true' : 'false');
    });
    const seg = h('div', { class: 'seg seg-4', role: 'tablist', 'aria-label': 'Auto-update interval' });
    const paint = (v) => {
      for (let i = 0; i < seg.children.length; i++) {
        const on = Number(seg.children[i].getAttribute('data-v')) === Number(v);
        seg.children[i].classList.toggle('is-on', on);
        seg.children[i].setAttribute('aria-selected', on ? 'true' : 'false');
      }
    };
    AUTO_CHOICES.forEach((c) => {
      const b = h('button', { class: 'seg-btn', type: 'button', role: 'tab', 'data-v': String(c[0]), text: c[1] });
      b.addEventListener('click', async () => {
        for (let i = 0; i < seg.children.length; i++) seg.children[i].disabled = true;
        const r = await saveSetting('autoupdate', c[0]);
        for (let i = 0; i < seg.children.length; i++) seg.children[i].disabled = false;
        if (r.ok) paint(c[0]);
      });
      seg.appendChild(b);
    });
    paint(st.autoupdate || 0);
    const auto = h('div', { class: 'set-block' },
      h('div', { class: 'set-name', text: '🔄 Auto-update' }),
      h('div', { class: 'set-desc', text: 'Check your lists on a schedule and download only what changed. While it is on, one small sleeping process wakes up every 15 minutes to see whether a check is due.' }),
      seg
    );
    Modal.show({
      icon: '⚙️',
      title: 'Settings',
      body: [live, auto, note('🌙 The sun and moon button at the top switches between the dark and light theme.')],
      view: 'settings',
      actions: gotIt()
    });
  }

  function diagIcon(level) {
    return { ok: '✅', warn: '⚠️', err: '❌', info: 'ℹ️' }[level] || 'ℹ️';
  }

  function diagView(d) {
    const sum = d.summary || { ok: 0, warn: 0, err: 0 };
    let line = '✅ Everything looks healthy.';
    if (sum.err) line = '❌ ' + sum.err + ' ' + plural(sum.err, 'problem needs', 'problems need') + ' attention.';
    else if (sum.warn) line = '⚠️ ' + sum.warn + ' ' + plural(sum.warn, 'thing', 'things') + ' worth a look.';
    const list = h('div', { class: 'diag-list' }, (d.checks || []).map((c) => h('div', { class: 'diag is-' + c.level },
      h('span', { class: 'diag-ico', text: diagIcon(c.level) }),
      h('div', { class: 'diag-body' }, h('div', { class: 'diag-t', text: c.title }), h('div', { class: 'diag-d', text: c.detail }))
    )));
    return [h('div', { class: 'diag-sum', text: line }), list];
  }

  async function showDiag() {
    const btn = $('act-diag');
    btn.disabled = true;
    Modal.show({ icon: '🩺', title: 'Health check', body: [para('Checking the hosts file, the mount, your lists and the network…', 'center')], view: 'diag', actions: [] });
    const r = await api('diag');
    btn.disabled = false;
    if (Modal.view() !== 'diag') return;
    if (!r.ok) {
      Modal.show({ icon: '❌', title: 'Health check failed', body: [para(stripLead(r.message), 'center')], view: 'result', actions: gotIt() });
      return;
    }
    Modal.show({
      icon: '🩺',
      title: 'Health check',
      body: diagView(r.data),
      view: 'diag',
      actions: [
        { label: '📋 Report', class: 'btn-ghost', onClick: () => showReport(r.data) },
        { label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }
      ]
    });
  }

  function reportText(st, diag) {
    const out = ['StevenBlock ' + (st.version || VERSION) + ' (' + (st.versionCode || VERSION_CODE) + ') report', ''];
    statusRows(st).forEach((row) => out.push(row[0] + ': ' + row[1]));
    if (st.conflicts && st.conflicts.length) out.push('Conflicting modules: ' + st.conflicts.join(', '));
    if (diag && diag.checks) {
      out.push('', 'Health check');
      diag.checks.forEach((c) => out.push(diagIcon(c.level) + ' ' + c.title + ': ' + c.detail));
    }
    const logs = (S.logs || []).slice(-40);
    if (logs.length) {
      out.push('', 'Recent log');
      logs.forEach((l) => out.push(new Date(l.t * 1000).toISOString().replace('T', ' ').slice(0, 19) + ' ' + l.l + ' ' + l.m));
    }
    return out.join('\n');
  }

  async function showReport(diag) {
    const r = await api('status');
    if (!r.ok) {
      toast(r.message, 'err');
      return;
    }
    await loadLogs();
    textSheet({ icon: '📋', title: 'Report', text: reportText(r.data, diag), hint: 'Paste this into a bug report. It holds no personal data — only StevenBlock’s own state.' });
  }

  async function repairFlow() {
    if (S.busy || S.syncBusy) return;
    const ok = await confirmBox({
      icon: '🛠️',
      title: 'Repair StevenBlock?',
      body: [para('The hosts file is rebuilt from your cached lists and rules, checked again and mounted if needed. Nothing is downloaded.', 'center')],
      ok: '🛠️ Repair'
    });
    if (!ok) return;
    Modal.close();
    setSyncBusy(true);
    const r = await api('repair');
    setSyncBusy(false);
    toast(r.message, r.ok ? 'ok' : 'err');
    refreshAll();
  }

  function extractDomain(raw, type) {
    let s = String(raw || '').trim();
    if (!s) return { err: ERR.empty };
    if (/\s/.test(s)) return { err: ERR.space };
    let wild = false;
    if (s.indexOf('*.') === 0) {
      if (type === 'block') return { err: ERR.wildblock };
      wild = true;
      s = s.slice(2);
    }
    if (s.indexOf('*') >= 0) return { err: type === 'block' ? ERR.wildblock : ERR.wildcard };
    const scheme = /^[a-z][a-z0-9+.-]*:\/\//i.test(s);
    if (!scheme) {
      const hostPart = s.split(/[/?#]/)[0];
      if (hostPart.indexOf(':') >= 0 || hostPart.charAt(0) === '[') return { err: ERR.port };
    }
    let host = '';
    try {
      host = new URL(scheme ? s : 'http://' + s).hostname;
    } catch (e) {
      return { err: ERR.invalid };
    }
    host = host.toLowerCase().replace(/\.$/, '');
    if (!host) return { err: ERR.empty };
    if (host.charAt(0) === '[' || host.indexOf(':') >= 0) return { err: ERR.port };
    if (/^[0-9.]+$/.test(host)) return { err: ERR.ip };
    if (host.length > 253) return { err: ERR.invalid };
    const labels = host.split('.');
    if (labels.length < 2) return { err: ERR.invalid };
    for (let i = 0; i < labels.length; i++) {
      const l = labels[i];
      if (l.length < 1 || l.length > 63) return { err: ERR.invalid };
      if (i < labels.length - 1) {
        if (!/^[a-z0-9_]([a-z0-9_-]*[a-z0-9_])?$/.test(l)) return { err: ERR.invalid };
      } else if (!/^[a-z]{2,}$/.test(l) && !/^xn--[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(l)) {
        return { err: ERR.invalid };
      }
    }
    return { domain: (wild ? '*.' : '') + host, wild: wild };
  }

  function setRuleMsg(text, kind) {
    const m = $('rule-msg');
    m.textContent = text || '';
    m.className = 'field-msg' + (kind ? ' is-' + kind : '');
    m.title = text || '';
  }

  function previewRule() {
    const v = $('rule-input').value;
    if (!v.trim()) {
      setRuleMsg('', '');
      return;
    }
    const r = extractDomain(v, 'allow');
    if (r.domain && r.wild) setRuleMsg('→ ' + r.domain + ' allows ' + r.domain.slice(2) + ' and every subdomain', '');
    else if (r.domain && r.domain !== v.trim().toLowerCase()) setRuleMsg('→ ' + r.domain, '');
    else setRuleMsg('', '');
  }

  function takeRules(data) {
    if (data && data.rules) S.rules = { allow: data.rules.allow || [], block: data.rules.block || [] };
  }

  async function addRule(type, value) {
    if (S.busy || S.syncBusy) return false;
    const input = $('rule-input');
    const r = extractDomain(value === undefined ? input.value : value, type);
    if (r.err) {
      setRuleMsg(r.err, 'err');
      return false;
    }
    const other = type === 'allow' ? 'block' : 'allow';
    const cap = (t) => (t === 'allow' ? 'Allow' : 'Block');
    if (S.rules[type].indexOf(r.domain) >= 0) {
      setRuleMsg('⚠️ ' + r.domain + ' is already in your ' + cap(type) + ' list.', 'err');
      return false;
    }
    if (S.rules[other].indexOf(r.domain) >= 0) {
      setRuleMsg('⚠️ Already in ' + cap(other) + ' list. Remove ' + r.domain + ' there first.', 'err');
      return false;
    }
    if (S.rules[type].length >= RULE_MAX) {
      setRuleMsg('📦 You’ve reached the limit of ' + fmtNum(RULE_MAX) + ' rules for this list. Remove some first.', 'err');
      return false;
    }
    const btn = $(type === 'allow' ? 'rule-allow' : 'rule-block');
    const label = btn.textContent;
    btn.textContent = '⏳ Saving…';
    setSyncBusy(true);
    const res = await api('rule-add', [type, r.domain]);
    setSyncBusy(false);
    btn.textContent = label;
    if (res.ok) {
      input.value = '';
      setRuleMsg('', '');
      takeRules(res.data);
      S.tab = type;
      renderRules();
      toast(res.message, 'ok');
      loadStatus();
      loadLogs();
      return true;
    }
    setRuleMsg(res.message, 'err');
    return false;
  }

  async function deleteRule(type, domain, btn) {
    if (S.busy || S.syncBusy) return false;
    if (btn) btn.disabled = true;
    setSyncBusy(true);
    const res = await api('rule-del', [type, domain]);
    setSyncBusy(false);
    if (res.ok) {
      takeRules(res.data);
      renderRules();
      toast(res.message, 'ok');
      loadStatus();
      loadLogs();
      return true;
    }
    if (btn) btn.disabled = false;
    toast(res.message, 'err');
    return false;
  }

  function hideLookup() {
    S.lookup = null;
    const box = $('lookup');
    box.hidden = true;
    clear(box);
  }

  function lookupAction(label, cls, fn) {
    const b = h('button', { class: 'btn btn-xs ' + cls, type: 'button', text: label });
    b.disabled = S.busy || S.syncBusy;
    b.addEventListener('click', async () => {
      const ok = await fn();
      if (ok) runLookup(S.lookup ? S.lookup.query : '');
    });
    return b;
  }

  function renderLookup(r) {
    const box = clear($('lookup'));
    const d = r.data || {};
    S.lookup = d;
    box.hidden = false;
    let cls = 'lookup';
    if (d.type === 'domain' && d.status === 'blocked') cls += ' is-blocked';
    else if (d.type === 'domain' && (d.status === 'clear' || d.status === 'allowed')) cls += ' is-clear';
    box.className = cls;
    box.appendChild(h('div', { class: 'lk-msg', text: r.message }));
    if (d.applied === 'pending') box.appendChild(h('div', { class: 'lk-sub', text: '🟡 This reflects your saved setup. It becomes active after a reboot.' }));
    if (d.type === 'keyword') {
      if (d.matchCount > 0) {
        const more = d.matchCount > d.matches.length ? ' Showing the first ' + d.matches.length + '.' : '';
        box.appendChild(h('div', { class: 'lk-sub', text: 'Tap a domain to check it.' + more }));
        box.appendChild(h('div', { class: 'lk-chips' }, d.matches.map((m) => {
          const c = h('button', { class: 'chiplet', type: 'button', text: m });
          c.addEventListener('click', () => {
            $('rule-input').value = m;
            runLookup(m);
          });
          return c;
        })));
      }
      return;
    }
    if (d.subCount > 0) {
      const sample = d.subs.slice(0, 3).join(', ');
      box.appendChild(h('div', { class: 'lk-sub', text: '🧩 ' + fmtNum(d.subCount) + ' blocked ' + plural(d.subCount, 'subdomain', 'subdomains') + ', such as ' + sample + '.' }));
    }
    const acts = [];
    if (d.status === 'blocked' && d.rule === 'block') acts.push(lookupAction('🗑️ Remove my block rule', 'btn-ghost', () => deleteRule('block', d.domain)));
    else if (d.status === 'blocked') acts.push(lookupAction('✅ Allow it', 'btn-allow', () => addRule('allow', d.domain)));
    if (d.status === 'allowed' && d.ref) acts.push(lookupAction('🗑️ Remove my allow rule', 'btn-ghost', () => deleteRule('allow', d.ref)));
    if (d.status === 'clear') acts.push(lookupAction('⛔ Block it', 'btn-block', () => addRule('block', d.domain)));
    if (d.subCount > 0 && d.status !== 'allowed' && d.status !== 'disabled') acts.push(lookupAction('✅ Allow all subdomains', 'btn-allow', () => addRule('allow', '*.' + d.domain)));
    if (acts.length) box.appendChild(h('div', { class: 'lk-actions' }, acts));
  }

  async function runLookup(value) {
    const input = $('rule-input');
    const q = String(value === undefined ? input.value : value).trim();
    if (!q) {
      setRuleMsg('✏️ Enter a domain or a keyword first.', 'err');
      hideLookup();
      return;
    }
    const btn = $('rule-check');
    btn.disabled = true;
    const r = await api('lookup', [q]);
    btn.disabled = false;
    if (!r.ok) {
      hideLookup();
      setRuleMsg(r.message, 'err');
      return;
    }
    setRuleMsg('', '');
    renderLookup(r);
  }

  function rulesAsText() {
    const out = [];
    S.rules.allow.forEach((d) => out.push('allow ' + d));
    S.rules.block.forEach((d) => out.push('block ' + d));
    return out.join('\n');
  }

  function exportRules() {
    const n = S.rules.allow.length + S.rules.block.length;
    if (!n) {
      toast('🌱 You have no rules to export yet.', 'info');
      return;
    }
    textSheet({ icon: '📤', title: 'Export rules', text: rulesAsText(), hint: n + ' ' + plural(n, 'rule', 'rules') + '. Keep this text somewhere safe and paste it into 📥 Import to restore it.' });
  }

  function parseRules(text, fallback) {
    const out = { allow: [], block: [], skipped: 0 };
    const seen = {};
    String(text || '').split(/\r?\n/).forEach((raw) => {
      let line = raw;
      const hash = line.indexOf('#');
      if (hash >= 0) line = line.slice(0, hash);
      line = line.trim();
      if (!line) return;
      let type = fallback;
      let rest = line;
      const m = /^(allow|block)\s+(.*)$/i.exec(line);
      if (m) {
        type = m[1].toLowerCase();
        rest = m[2];
      } else if (/^(0\.0\.0\.0|127\.0\.0\.1)\s+/.test(line)) {
        type = 'block';
        rest = line.replace(/^\S+\s+/, '');
      } else if (line.charAt(0) === '+') {
        type = 'allow';
        rest = line.slice(1);
      } else if (line.charAt(0) === '-') {
        type = 'block';
        rest = line.slice(1);
      }
      rest.split(/[\s,;]+/).forEach((tok) => {
        if (!tok) return;
        const r = extractDomain(tok, type);
        if (r.err || seen[r.domain]) {
          out.skipped++;
          return;
        }
        seen[r.domain] = true;
        out[type].push(r.domain);
      });
    });
    return out;
  }

  async function sendImport(allow, block, mode) {
    const limit = 40000;
    const batches = [];
    let a = [];
    let b = [];
    let size = 0;
    const flush = () => {
      batches.push([a, b]);
      a = [];
      b = [];
      size = 0;
    };
    allow.forEach((d) => {
      if (size + d.length + 1 > limit) flush();
      a.push(d);
      size += d.length + 1;
    });
    block.forEach((d) => {
      if (size + d.length + 1 > limit) flush();
      b.push(d);
      size += d.length + 1;
    });
    if (a.length || b.length || !batches.length) flush();
    let last = null;
    let added = 0;
    let skipped = 0;
    for (let i = 0; i < batches.length; i++) {
      last = await api('rules-import', [batches[i][0].join(','), batches[i][1].join(','), i === 0 ? mode : 'merge']);
      const d = last.data || {};
      added += Number(d.added) || 0;
      skipped += (Number(d.invalid) || 0) + (Number(d.duplicate) || 0) + (Number(d.conflict) || 0) + (Number(d.limit) || 0);
      if (!last.ok && last.code !== 'import_nothing') break;
    }
    if (batches.length > 1 && last && (last.ok || last.code === 'import_nothing')) {
      return {
        ok: added > 0 || mode === 'replace',
        code: added > 0 || mode === 'replace' ? 'rules_imported' : 'import_nothing',
        message: (added > 0 || mode === 'replace' ? '📥 Imported ' + added + ' ' + plural(added, 'rule', 'rules') + '.' : 'ℹ️ Nothing new to import.') + (skipped ? ' ' + skipped + ' skipped.' : ''),
        data: last.data
      };
    }
    return last;
  }

  function importRules() {
    if (S.busy || S.syncBusy) return;
    let mode = 'merge';
    let fallback = S.tab;
    const ta = h('textarea', { class: 'area', spellcheck: 'false', autocapitalize: 'off', autocorrect: 'off', 'aria-label': 'Rules to import', placeholder: 'allow example.com\nallow *.cdn.example.com\nblock ads.example.net\n\nPlain domains, one per line, work too.' });
    const info = h('p', { class: 'fine', text: 'Paste an exported list, or one domain per line.' });
    const seg = (items, current, onPick) => {
      const box = h('div', { class: 'seg seg-2', role: 'tablist' });
      items.forEach((it) => {
        const b = h('button', { class: 'seg-btn' + (it[0] === current ? ' is-on' : ''), type: 'button', role: 'tab', 'aria-selected': it[0] === current ? 'true' : 'false', text: it[1] });
        b.addEventListener('click', () => {
          for (let i = 0; i < box.children.length; i++) {
            box.children[i].classList.toggle('is-on', box.children[i] === b);
            box.children[i].setAttribute('aria-selected', box.children[i] === b ? 'true' : 'false');
          }
          onPick(it[0]);
        });
        box.appendChild(b);
      });
      return box;
    };
    const refresh = () => {
      const p = parseRules(ta.value, fallback);
      if (!ta.value.trim()) {
        info.textContent = 'Paste an exported list, or one domain per line.';
        info.className = 'fine';
        return p;
      }
      info.textContent = '✅ ' + p.allow.length + ' allow · ⛔ ' + p.block.length + ' block' + (p.skipped ? ' · 🚫 ' + p.skipped + ' skipped' : '');
      info.className = 'fine' + (p.allow.length + p.block.length ? ' is-ok' : ' is-err');
      return p;
    };
    ta.addEventListener('input', refresh);
    const submit = async () => {
      const p = refresh();
      if (!p.allow.length && !p.block.length && mode !== 'replace') {
        info.textContent = '✏️ There is nothing to import yet.';
        info.className = 'fine is-err';
        return;
      }
      if (mode === 'replace') {
        const sure = await confirmBox({
          icon: '♻️',
          title: 'Replace all rules?',
          body: [para('Your ' + (S.rules.allow.length + S.rules.block.length) + ' current rules are removed and replaced by the ' + (p.allow.length + p.block.length) + ' rules you pasted.', 'center')],
          ok: '♻️ Replace',
          okClass: 'btn-danger'
        });
        if (!sure) return;
      }
      Modal.close();
      setSyncBusy(true);
      const r = await sendImport(p.allow, p.block, mode);
      setSyncBusy(false);
      takeRules(r.data);
      renderRules();
      toast(r.message, r.ok ? 'ok' : (r.code === 'import_nothing' ? 'info' : 'err'));
      loadStatus();
      loadLogs();
    };
    Modal.show({
      icon: '📥',
      title: 'Import rules',
      body: [
        ta,
        info,
        h('div', { class: 'set-desc', text: 'Lines without allow or block count as:' }),
        seg([['allow', '✅ Allow'], ['block', '⛔ Block']], fallback, (v) => { fallback = v; refresh(); }),
        h('div', { class: 'set-desc', text: 'What should happen to your current rules?' }),
        seg([['merge', '➕ Keep and add'], ['replace', '♻️ Replace all']], mode, (v) => { mode = v; })
      ],
      view: 'import',
      actions: [
        { label: '↩️ Not now', class: 'btn-ghost', onClick: () => Modal.close() },
        { label: '📥 Import', class: 'btn-primary', onClick: submit }
      ]
    });
  }

  async function refreshMeta(id) {
    if (id && cards[id]) {
      cards[id].retry.disabled = true;
    }
    const r = await api('meta-refresh', id ? [id] : []);
    if (!r.ok) {
      toast(r.message, 'err');
      if (id && cards[id]) cards[id].retry.disabled = false;
      return;
    }
    if (S.lists) {
      S.refreshing = true;
      S.lists.lists.forEach((l) => {
        if (!id || l.id === id) {
          l.busy = true;
          l.error = '';
          l.count = null;
        }
      });
      if (!id) {
        (S.lists.addons || []).forEach((a) => {
          a.busy = true;
          a.error = '';
        });
      }
      renderLists();
    }
    if (!id) toast(r.message, 'info');
    scheduleLists(800);
  }

  async function clearLogs() {
    const ok = await confirmBox({
      icon: '🧹',
      title: 'Clear all logs?',
      body: [para('This removes every log entry. It doesn’t change your lists, rules or hosts file.', 'center')],
      ok: '🧹 Clear logs',
      okClass: 'btn-danger'
    });
    if (!ok) return;
    Modal.close();
    const r = await api('logs-clear');
    toast(r.message, r.ok ? 'ok' : 'err');
    loadLogs();
  }

  function copyLogs() {
    const logs = visibleLogs();
    if (!logs.length) {
      toast('📭 There is nothing to copy.', 'info');
      return;
    }
    const text = logs.map((l) => new Date(l.t * 1000).toISOString().replace('T', ' ').slice(0, 19) + ' ' + l.l + ' ' + l.m).join('\n');
    textSheet({ icon: '📜', title: 'Copy logs', text: text, hint: logs.length + ' log ' + plural(logs.length, 'entry', 'entries') + '.' });
  }

  async function openLink(id) {
    const r = await api('open', [id]);
    toast(r.message, r.ok ? 'info' : 'err');
  }

  async function loadStatus() {
    const r = await api('status');
    if (r.ok) {
      S.status = r.data;
      if (r.data.op && r.data.op.running) S.busy = true;
      renderStatus();
      if (S.lists) renderLists();
      handleOp(r.data.op);
    }
    return r;
  }

  let listsTimer = 0;

  function scheduleLists(ms) {
    clearTimeout(listsTimer);
    listsTimer = setTimeout(loadLists, ms);
  }

  async function loadLists() {
    const r = await api('lists');
    if (r.ok) {
      S.lists = r.data;
      S.refreshing = !!r.data.refreshing;
      renderLists();
      if (S.refreshing) scheduleLists(1500);
    }
    return r;
  }

  async function loadRules() {
    const r = await api('rules');
    if (r.ok) {
      S.rules = { allow: r.data.allow || [], block: r.data.block || [] };
      renderRules();
    }
    return r;
  }

  async function loadLogs() {
    const r = await api('logs');
    if (r.ok) {
      S.logs = r.data.logs || [];
      renderLogs();
    }
    return r;
  }

  function refreshAll() {
    loadStatus();
    loadLists();
    loadRules();
    loadLogs();
  }

  function setupTheme() {
    const btn = $('theme-btn');
    const meta = document.querySelector('meta[name="theme-color"]');
    const apply = (t) => {
      document.documentElement.setAttribute('data-theme', t);
      btn.textContent = t === 'dark' ? '☀️' : '🌙';
      btn.setAttribute('aria-label', t === 'dark' ? 'Switch to light theme' : 'Switch to dark theme');
      if (meta) meta.setAttribute('content', t === 'dark' ? '#06080d' : '#eef2f7');
    };
    apply(document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark');
    btn.addEventListener('click', () => {
      const next = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
      apply(next);
      store.set('sb-theme', next);
    });
  }

  function setupGuards() {
    const allowed = (t) => {
      const n = t && t.nodeType === 3 ? t.parentElement : t;
      return !!(n && n.closest && n.closest('input, textarea'));
    };
    ['contextmenu', 'copy', 'cut', 'selectstart', 'dragstart'].forEach((ev) => {
      document.addEventListener(ev, (e) => {
        if (!allowed(e.target)) e.preventDefault();
      });
    });
  }

  function setupLite() {
    const mem = Number(navigator.deviceMemory) || 0;
    const cores = Number(navigator.hardwareConcurrency) || 0;
    if ((mem && mem <= 2) || (cores && cores <= 4)) document.documentElement.classList.add('lite');
  }

  function bindEvents() {
    const nav = document.querySelectorAll('.chip');
    for (let i = 0; i < nav.length; i++) {
      nav[i].addEventListener('click', (e) => {
        e.preventDefault();
        const id = (nav[i].getAttribute('href') || '').slice(1);
        const target = $(id);
        if (!target) return;
        const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        target.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
      });
    }
    $('ribbon-btn').addEventListener('click', () => {
      const mode = $('ribbon-btn').getAttribute('data-mode');
      if (mode === 'reboot' || mode === 'inactive') rebootFlow();
      else if (mode === 'setup' && S.status) runUpdate();
    });
    $('lists-refresh').addEventListener('click', () => refreshMeta(''));
    $('addon-apply').addEventListener('click', applyAddons);
    $('addon-reset').addEventListener('click', resetAddons);
    $('rule-input').addEventListener('input', () => {
      previewRule();
      if (S.lookup) hideLookup();
    });
    $('rule-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        $('rule-input').blur();
        runLookup();
      }
    });
    $('rule-allow').addEventListener('click', () => addRule('allow'));
    $('rule-block').addEventListener('click', () => addRule('block'));
    $('rule-check').addEventListener('click', () => runLookup());
    $('rules-import').addEventListener('click', importRules);
    $('rules-export').addEventListener('click', exportRules);
    $('rule-filter').addEventListener('input', () => {
      S.ruleFilter = $('rule-filter').value;
      renderRules();
    });
    $('tab-allow').addEventListener('click', () => { S.tab = 'allow'; renderRules(); });
    $('tab-block').addEventListener('click', () => { S.tab = 'block'; renderRules(); });
    $('act-update').addEventListener('click', runUpdate);
    $('act-status').addEventListener('click', showStatusDialog);
    $('act-toggle').addEventListener('click', toggleBlocker);
    $('act-diag').addEventListener('click', showDiag);
    $('act-settings').addEventListener('click', showSettings);
    $('act-repair').addEventListener('click', repairFlow);
    $('logs-refresh').addEventListener('click', () => { S.logSig = ''; loadLogs(); });
    $('logs-copy').addEventListener('click', copyLogs);
    $('logs-clear').addEventListener('click', clearLogs);
    const fs = document.querySelectorAll('.filter');
    for (let i = 0; i < fs.length; i++) {
      fs[i].addEventListener('click', () => setLogLevel(fs[i].getAttribute('data-level')));
    }
    $('gate-retry').addEventListener('click', retryGate);
    $('mini').addEventListener('click', () => {
      if (S.op && S.op.running) {
        S.opView = true;
        showProgress(S.op);
      }
    });
    const links = document.querySelectorAll('[data-link]');
    for (let i = 0; i < links.length; i++) {
      links[i].addEventListener('click', () => openLink(links[i].getAttribute('data-link')));
    }
    document.addEventListener('visibilitychange', () => {
      if (document.hidden || !S.ready || S.gate) return;
      loadStatus();
      if (S.busy) schedulePoll(0);
    });
    setInterval(() => {
      if (!document.hidden && S.ready && !S.gate) loadLogs();
    }, 10000);
    setInterval(() => {
      if (!document.hidden && S.ready && !S.gate && !S.busy) loadStatus();
    }, 60000);
  }

  async function start() {
    if (Bridge.mode === 'http' && Bridge.framed()) {
      showGate('framed');
      return;
    }
    if (Bridge.mode === 'http' && !Bridge.hasToken()) {
      showGate('no_token');
      return;
    }
    const r = await loadStatus();
    if (!r.ok) {
      if (!S.gate) showGate('bridge');
      return;
    }
    S.ready = true;
    await Promise.all([loadLists(), loadRules(), loadLogs()]);
  }

  function init() {
    setupLite();
    setupTheme();
    setupGuards();
    $('toggle-icon').innerHTML = POWER;
    bindEvents();
    start();
  }

  init();
})();
