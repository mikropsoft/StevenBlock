(() => {
  'use strict';

  const MOD = '/data/adb/modules/stevenblock';
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
  const POWER = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 3.2v8.4" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/><path d="M6.5 6.8a7.7 7.7 0 1 0 11 0" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>';
  const FAIL = {
    bridge: '❌ StevenBlock didn’t respond. Please try again.',
    offline: '🔌 The local WebUI server isn’t running anymore.',
    unauthorized: '🔑 This session has expired.',
    no_token: '🔑 No secure session was found.'
  };
  const ERR = {
    empty: '✏️ Enter a domain first.',
    space: '🚫 Spaces aren’t allowed in a domain.',
    wildcard: '🚫 Wildcards (*) aren’t supported by hosts files. Enter the exact domain.',
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
    logs: [],
    logSig: '',
    op: null,
    busy: false,
    syncBusy: false,
    opView: false,
    seen: Number(store.get('sb-seq')) || 0,
    speed: { t: 0, b: 0, v: 0 },
    ready: false,
    gate: ''
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

  function ago(sec) {
    if (!sec) return 'Never';
    const d = Math.max(0, Date.now() / 1000 - sec);
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

  const Bridge = (() => {
    const k = (typeof window.ksu === 'object' && window.ksu && typeof window.ksu.exec === 'function') ? window.ksu : null;
    let token = '';
    let seq = 0;
    if (!k) {
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
        }, 90000);
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
      const a = args || [];
      if (k) {
        let r;
        try {
          r = await exec(['sh', quote(MOD + '/sb.sh'), quote(cmd)].concat(a.map(quote)).join(' '));
        } catch (e) {
          return fail('bridge');
        }
        return parse(r.stdout) || fail('bridge');
      }
      if (!token) return fail('no_token');
      const p = new URLSearchParams();
      p.set('t', token);
      p.set('c', cmd);
      if (a.length > 0) p.set('a', a[0]);
      if (a.length > 1) p.set('b', a[1]);
      let res;
      try {
        res = await fetch('cgi-bin/api?' + p.toString(), { cache: 'no-store', credentials: 'omit' });
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

    return { call: call, mode: k ? 'ksu' : 'http', hasToken: () => !!token };
  })();

  async function api(cmd, args) {
    const r = await Bridge.call(cmd, args);
    if (!r.ok && (r.code === 'offline' || r.code === 'unauthorized' || r.code === 'no_token')) showGate(r.code);
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

    $('modal-scrim').addEventListener('click', dismiss);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') dismiss();
    });

    return { show: show, close: close, open: () => isOpen, view: () => view };
  })();

  function para(text, cls) {
    return h('p', { class: cls || null, text: text });
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
      bridge: ['❌', 'Couldn’t reach StevenBlock', 'The module didn’t answer. Make sure StevenBlock is installed and enabled — if you just installed it, reboot first.']
    };
    const m = map[code] || map.bridge;
    $('gate-icon').textContent = m[0];
    $('gate-title').textContent = m[1];
    $('gate-text').textContent = m[2];
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

  function listName(id) {
    if (S.lists && S.lists.lists) {
      for (let i = 0; i < S.lists.lists.length; i++) if (S.lists.lists[i].id === id) return S.lists.lists[i].name;
    }
    if (S.status && S.status.list === id) return S.status.listName;
    return id || 'your list';
  }

  function findList(id) {
    if (!S.lists || !S.lists.lists) return null;
    for (let i = 0; i < S.lists.lists.length; i++) if (S.lists.lists[i].id === id) return S.lists.lists[i];
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
    $('ver').textContent = st.version || 'v1.0';
    $('credits-ver').textContent = 'StevenBlock ' + (st.version || 'v1.0') + ' • 🔒 Local only • No telemetry • Inter by Rasmus Andersson (SIL OFL 1.1)';

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

    const hl = clear($('hero-list'));
    hl.appendChild(h('span', { class: 'hl-name', text: '📋 ' + (st.listName || 'StevenBlack Main') }));
    hl.appendChild(h('span', { class: 'lvl lvl-' + (st.level || 'green'), text: (LEVEL[st.level] || '🟢') + ' ' + (st.levelText || '') }));
    $('stat-rules').textContent = '✅ ' + fmtNum(st.allow) + '  ·  ⛔ ' + fmtNum(st.block);
    $('stat-updated').textContent = st.setup === 'ready' ? ago(st.updated) : 'Not yet';
    const ap = appliedText(st.applied);
    const apEl = $('hero-applied');
    apEl.textContent = ap[0];
    apEl.className = 'hero-applied ' + ap[1];

    const tgl = $('act-toggle');
    tgl.classList.toggle('is-danger', !!st.enabled);
    tgl.classList.toggle('is-on', !st.enabled);
    $('toggle-label').textContent = st.enabled ? 'Disable Blocker' : 'Enable Blocker';
    $('actions-note').textContent = st.enabled
      ? '🔄 Updates only download when the source list has changed.'
      : '🔴 The blocker is off. Enable it to switch or update lists.';
    $('lists-note').textContent = st.enabled
      ? 'Pick a blocklist. Stronger lists block more, but can break more.'
      : '🔴 The blocker is off. Enable it in ⚡ Actions to switch or update lists.';
    applyBusy();
  }

  const cards = {};

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
    const list = R[S.tab] || [];
    if (!list.length) {
      ul.appendChild(h('li', { class: 'empty', text: S.tab === 'allow' ? '🌱 No allow rules yet. Add a domain above to always let it through.' : '🌱 No block rules yet. Add a domain above to always block it.' }));
      return;
    }
    const type = S.tab;
    list.slice().reverse().forEach((d) => {
      const x = h('button', { class: 'rule-x', type: 'button', 'aria-label': 'Remove ' + d, text: '🗑️' });
      x.disabled = S.busy || S.syncBusy;
      x.addEventListener('click', () => deleteRule(type, d, x));
      ul.appendChild(h('li', { class: 'rule' }, h('span', { class: 'rule-d', text: (type === 'allow' ? '✅ ' : '⛔ ') + d }), x));
    });
  }

  function renderLogs() {
    const box = $('logbox');
    const logs = S.logs || [];
    const last = logs.length ? logs[logs.length - 1] : null;
    const sig = logs.length + '|' + (last ? last.t + last.m : '');
    if (sig === S.logSig) return;
    const first = S.logSig === '';
    S.logSig = sig;
    const nearBottom = box.scrollHeight - box.scrollTop - box.clientHeight < 48;
    clear(box);
    if (!logs.length) {
      box.appendChild(h('div', { class: 'empty', text: '📭 No log entries yet.' }));
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

  function applyBusy() {
    const st = S.status;
    const busy = S.busy || S.syncBusy;
    const enabled = st ? !!st.enabled : true;
    $('act-update').disabled = busy || !enabled || !st;
    $('act-toggle').disabled = busy || !st;
    $('rule-allow').disabled = busy;
    $('rule-block').disabled = busy;
    $('logs-clear').disabled = false;
    Object.keys(cards).forEach((id) => {
      const c = cards[id];
      c.use.disabled = busy || !enabled;
    });
    const xs = document.querySelectorAll('.rule-x');
    for (let i = 0; i < xs.length; i++) xs[i].disabled = busy;
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
    if (op.kind === 'update') return 'Updating ' + name;
    if (op.kind === 'enable') return 'Turning blocking back on';
    if (op.kind === 'setup') return 'Downloading ' + name;
    return 'Installing ' + name;
  }

  function opIcon(op) {
    return op.kind === 'update' ? '🔄' : '⬇️';
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

  function updateProgress(op) {
    if (!PV.built) return;
    const n = progressNumbers(op);
    const speed = trackSpeed(op);
    PV.steps.forEach((el, i) => {
      el.classList.toggle('is-done', i < n.idx);
      el.classList.toggle('is-active', i === n.idx);
    });
    PV.phase.textContent = op.cancelling ? '✖️ Cancelling…' : (PHASE_TEXT[op.phase] || PHASE_TEXT.prepare);
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
    const name = listName(op.list);
    let text = (PHASE_TEXT[op.phase] || PHASE_TEXT.prepare).replace('…', '') + ' • ' + name;
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
      if (!wasBusy && !S.opView && Modal.view() !== 'progress' && !Modal.open()) S.opView = true;
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
    const recent = wasBusy || (op.ended && Date.now() / 1000 - op.ended < 600);
    markSeen(op.seq);
    if (!recent) return;
    if (S.opView || Modal.view() === 'progress') showResult(op);
    else toast(op.message, op.state === 'success' ? 'ok' : (op.state === 'cancelled' ? 'info' : 'err'));
    S.opView = false;
    refreshAll();
  }

  function showResult(op) {
    const msg = stripLead(op.message);
    let icon = '✅';
    let title = 'Done';
    let actions = [{ label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }];
    const body = [para(msg, 'center')];
    if (op.state === 'success') {
      if (op.code === 'up_to_date') title = 'Already up to date';
      else if (op.code === 'unchanged') title = 'Nothing to change';
      else title = op.kind === 'update' ? 'List updated' : 'Ready to go';
      if (op.reboot) {
        body.push(h('div', { class: 'note is-warn', text: '💡 No rush — your current protection keeps working until you reboot.' }));
        actions = [
          { label: '⏰ Later', class: 'btn-ghost', onClick: () => Modal.close() },
          { label: '🔁 Reboot now', class: 'btn-warn', onClick: rebootFlow }
        ];
      }
    } else if (op.state === 'cancelled') {
      icon = '✖️';
      title = 'Cancelled';
    } else {
      icon = '❌';
      const t = { apply: 'Couldn’t switch lists', update: 'Update failed', enable: 'Couldn’t enable blocking', setup: 'Download failed' };
      title = t[op.kind] || 'Something went wrong';
      if (!/nothing was changed|restored|intact/i.test(op.message || '')) body.push(h('div', { class: 'note is-err', text: '🛟 Nothing was lost — your previous hosts file is still in place.' }));
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
    const t = { apply: 'Couldn’t switch lists', update: 'Couldn’t start the update', enable: 'Couldn’t enable blocking' };
    if (r.code === 'offline' || r.code === 'unauthorized' || r.code === 'no_token') {
      Modal.close();
      return;
    }
    Modal.show({
      icon: r.code === 'busy' ? '⏳' : (r.code === 'already_active' ? '⚠️' : '❌'),
      title: r.code === 'busy' ? 'Please wait' : (r.code === 'already_active' ? 'Already active' : (t[kind] || 'Something went wrong')),
      body: [para(stripLead(r.message), 'center')],
      view: 'result',
      actions: [{ label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }]
    });
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
      body.push(h('div', { class: 'note is-warn', text: '⚠️ This is a strict list. Some sites or app features may stop working — you can always allow a domain in 🧩 Domain Rules.' }));
    }
    body.push(h('div', { class: 'note', text: '🔁 A reboot is needed to activate it. Your domain rules are kept.' }));
    const ok = await confirmBox({ icon: '📋', title: 'Switch to ' + l.name + '?', body: body, ok: '⬇️ Apply list' });
    if (!ok) return;
    startApply(id);
  }

  async function startApply(id) {
    S.opView = true;
    S.speed = { t: 0, b: 0, v: 0 };
    showProgress({ running: true, kind: 'apply', list: id, phase: 'prepare', bytes: 0, total: 0, cancellable: false });
    const r = await api('apply', [id]);
    if (!r.ok) {
      showReplyError(r, 'apply');
      return;
    }
    handleOp(r.data.op);
    schedulePoll(400);
  }

  async function runUpdate() {
    const st = S.status;
    if (!st || !st.enabled || S.busy) return;
    S.opView = true;
    S.speed = { t: 0, b: 0, v: 0 };
    showProgress({ running: true, kind: st.setup === 'ready' ? 'update' : 'setup', list: st.list, phase: st.setup === 'ready' ? 'check' : 'prepare', bytes: 0, total: 0, cancellable: false });
    const r = await api('update');
    if (!r.ok) {
      showReplyError(r, 'update');
      return;
    }
    handleOp(r.data.op);
    schedulePoll(400);
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
        body: [para('Ads and trackers won’t be blocked after the next reboot. Your list and domain rules are kept, so you can turn it back on anytime.', 'center')],
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
      Modal.show({ icon: '❌', title: 'Couldn’t reboot', body: [para(stripLead(r.message), 'center')], view: 'result', actions: [{ label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }] });
    }
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
    const rows = [
      ['🛡️ Blocker', st.enabled ? '🟢 On' : '🔴 Off'],
      ['📋 Active list', st.listName || '—'],
      ['🎚️ Level', (LEVEL[st.level] || '') + ' ' + (st.levelText || '')],
      ['🔢 Domains blocked', st.setup === 'ready' ? (st.enabled ? fmtNum(st.domains) : '0 (paused)') : '—'],
      ['✅ Allow rules', fmtNum(st.allow)],
      ['⛔ Block rules', fmtNum(st.block)],
      ['🕒 Last update', st.updated && st.setup === 'ready' ? stampFmt.format(new Date(st.updated * 1000)) + ' · ' + ago(st.updated) : 'Never'],
      ['🔁 Reboot pending', st.reboot ? '🟡 Yes' : 'No'],
      ['🧪 Applied', appliedText(st.applied)[0]],
      ['🧰 Root manager', (st.manager || 'Unknown') + (st.managerVersion ? ' ' + st.managerVersion : '')],
      ['📦 Module version', (st.version || 'v1.0') + ' (' + (st.versionCode || 1000) + ')'],
      ['🔗 Mounted by', ({ manager: 'Root manager', self: 'StevenBlock (direct)', conflict: 'Another module', failed: '❌ Mount failed' })[st.mount] || '—'],
      ['🖥️ Interface', Bridge.mode === 'ksu' ? 'Root manager WebUI' : 'Local server · 127.0.0.1:9090']
    ];
    const list = h('div', { class: 'kv-list' }, rows.map((row) => h('div', { class: 'kv' }, h('span', { class: 'k', text: row[0] }), h('span', { class: 'v', text: row[1] }))));
    const body = [list];
    if (st.conflicts && st.conflicts.length) {
      const names = st.conflicts.map((c) => (c === 'hosts' ? 'Systemless hosts' : c)).join(', ');
      body.push(h('div', { class: 'note is-warn', text: '⚠️ These modules also replace /system/etc/hosts: ' + names + '. Disable them so StevenBlock can work.' }));
    }
    if (st.adaway) body.push(h('div', { class: 'note is-warn', text: '⚠️ AdAway is installed. Don’t use its root or systemless mode together with StevenBlock.' }));
    if (st.applied === 'pending') body.push(h('div', { class: 'note', text: '🔁 Your latest changes are saved and become active after a reboot.' }));
    if (st.applied === 'inactive') {
      body.push(h('div', { class: 'note is-err', text: st.mount === 'failed'
        ? '🔴 Android isn’t using StevenBlock’s hosts file, and mounting it at startup failed. Check 📜 Logs for details.'
        : '🔴 Android isn’t using StevenBlock’s hosts file yet. Reboot — StevenBlock mounts it automatically at startup.' }));
    }
    if (st.applied === 'applied' && st.mount === 'self') body.push(h('div', { class: 'note', text: '🔗 Your root manager didn’t mount the hosts file, so StevenBlock mounted it directly. Blocking works normally.' }));
    Modal.show({ icon: '📊', title: 'Status', body: body, view: 'status', actions: [{ label: '👌 Got it', class: 'btn-primary', onClick: () => Modal.close() }] });
  }

  function extractDomain(raw) {
    const s = String(raw || '').trim();
    if (!s) return { err: ERR.empty };
    if (/\s/.test(s)) return { err: ERR.space };
    if (s.indexOf('*') >= 0) return { err: ERR.wildcard };
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
    return { domain: host };
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
    const r = extractDomain(v);
    if (r.domain && r.domain !== v.trim().toLowerCase()) setRuleMsg('→ ' + r.domain, '');
    else setRuleMsg('', '');
  }

  async function addRule(type) {
    if (S.busy || S.syncBusy) return;
    const input = $('rule-input');
    const r = extractDomain(input.value);
    if (r.err) {
      setRuleMsg(r.err, 'err');
      return;
    }
    const other = type === 'allow' ? 'block' : 'allow';
    const cap = (t) => (t === 'allow' ? 'Allow' : 'Block');
    if (S.rules[type].indexOf(r.domain) >= 0) {
      setRuleMsg('⚠️ ' + r.domain + ' is already in your ' + cap(type) + ' list.', 'err');
      return;
    }
    if (S.rules[other].indexOf(r.domain) >= 0) {
      setRuleMsg('⚠️ Already in ' + cap(other) + ' list. Remove ' + r.domain + ' there first.', 'err');
      return;
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
      if (res.data.rules) S.rules = { allow: res.data.rules.allow || [], block: res.data.rules.block || [] };
      S.tab = type;
      renderRules();
      toast(res.message, 'ok');
      loadStatus();
      loadLogs();
    } else {
      setRuleMsg(res.message, 'err');
    }
  }

  async function deleteRule(type, domain, btn) {
    if (S.busy || S.syncBusy) return;
    btn.disabled = true;
    setSyncBusy(true);
    const res = await api('rule-del', [type, domain]);
    setSyncBusy(false);
    if (res.ok) {
      if (res.data.rules) S.rules = { allow: res.data.rules.allow || [], block: res.data.rules.block || [] };
      renderRules();
      toast(res.message, 'ok');
      loadStatus();
      loadLogs();
    } else {
      btn.disabled = false;
      toast(res.message, 'err');
    }
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
    $('rule-input').addEventListener('input', previewRule);
    $('rule-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        $('rule-input').blur();
      }
    });
    $('rule-allow').addEventListener('click', () => addRule('allow'));
    $('rule-block').addEventListener('click', () => addRule('block'));
    $('tab-allow').addEventListener('click', () => { S.tab = 'allow'; renderRules(); });
    $('tab-block').addEventListener('click', () => { S.tab = 'block'; renderRules(); });
    $('act-update').addEventListener('click', runUpdate);
    $('act-status').addEventListener('click', showStatusDialog);
    $('act-toggle').addEventListener('click', toggleBlocker);
    $('logs-refresh').addEventListener('click', () => { S.logSig = '#'; loadLogs(); });
    $('logs-clear').addEventListener('click', clearLogs);
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
