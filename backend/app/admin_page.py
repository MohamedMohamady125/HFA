"""Web admin dashboard for managing branches, served at /admin."""
from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

ADMIN_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>HFA Admin — Branches</title>
<style>
  :root {
    --primary: #003459; --primary-dark: #002540; --accent: #00A8E8; --accent-dark: #0089BF;
    --bg: #F6F8FA; --card: #FFFFFF; --text: #0F1419; --text-2: #536471; --text-3: #8899A6;
    --success: #00BA7C; --error: #EF2E43; --warning: #F59E0B; --divider: #EBF0F3;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
  body { background: var(--bg); color: var(--text); min-height: 100vh; }

  .hero { background: linear-gradient(135deg, #002540, #003459, #005A8D); color: #fff; padding: 28px 24px; border-radius: 0 0 28px 28px; }
  .hero-inner { max-width: 960px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
  .hero h1 { font-size: 26px; font-weight: 900; letter-spacing: -0.5px; }
  .hero p { font-size: 13.5px; opacity: .75; margin-top: 3px; }
  .hero .actions { display: flex; gap: 10px; }

  .container { max-width: 960px; margin: 24px auto; padding: 0 20px 60px; }

  .btn { border: 0; cursor: pointer; border-radius: 12px; font-weight: 700; font-size: 15px; padding: 13px 22px; transition: transform .12s ease, box-shadow .15s ease, opacity .15s; display: inline-flex; align-items: center; gap: 8px; min-height: 48px; }
  .btn:active { transform: scale(.97); }
  .btn-primary { background: linear-gradient(135deg, #00A8E8, #0077B6); color: #fff; box-shadow: 0 5px 14px rgba(0,168,232,.35); }
  .btn-ghost { background: rgba(255,255,255,.14); color: #fff; }
  .btn-outline { background: #fff; color: var(--primary); border: 1.5px solid #D8E1E8; }
  .btn-danger { background: #FDE8EA; color: var(--error); }
  .btn:disabled { opacity: .5; cursor: not-allowed; }

  .card { background: var(--card); border: .8px solid var(--divider); border-radius: 18px; box-shadow: 0 4px 16px rgba(0,52,89,.05); padding: 20px; margin-bottom: 14px; }

  /* login */
  .login-wrap { max-width: 420px; margin: 60px auto; padding: 0 20px; }
  .login-wrap h2 { font-size: 24px; font-weight: 900; letter-spacing: -.5px; margin-bottom: 4px; }
  .login-wrap .sub { color: var(--text-2); font-size: 14px; margin-bottom: 24px; }
  label { display: block; font-size: 13px; font-weight: 600; color: var(--text-2); letter-spacing: .3px; margin: 0 0 7px; }
  input, textarea { width: 100%; background: #F1F4F8; border: 1.6px solid transparent; border-radius: 12px; padding: 14px 16px; font-size: 15px; color: var(--text); outline: none; margin-bottom: 16px; transition: border-color .15s; }
  input:focus, textarea:focus { border-color: var(--accent); background: #fff; }
  textarea { resize: vertical; min-height: 90px; }
  .helper { font-size: 12px; color: var(--text-3); margin: -10px 0 16px; }
  .err { background: #FDE8EA; color: var(--error); font-size: 13.5px; font-weight: 600; border-radius: 10px; padding: 10px 14px; margin-bottom: 14px; display: none; }

  /* branch rows */
  .branch-head { display: flex; align-items: flex-start; gap: 14px; }
  .icon-badge { width: 46px; height: 46px; min-width: 46px; border-radius: 13px; background: rgba(0,168,232,.12); color: var(--accent); display: flex; align-items: center; justify-content: center; font-size: 20px; }
  .branch-title { font-size: 17px; font-weight: 800; letter-spacing: -.3px; }
  .branch-sub { font-size: 13px; color: var(--text-2); margin-top: 2px; }
  .chips { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 10px; }
  .chip { font-size: 11.5px; font-weight: 700; padding: 4px 10px; border-radius: 999px; }
  .chip.on { background: rgba(0,186,124,.1); color: var(--success); border: .8px solid rgba(0,186,124,.25); }
  .chip.off { background: #F1F4F8; color: var(--text-3); border: .8px solid var(--divider); }
  .row-actions { display: flex; gap: 8px; margin-left: auto; }
  .row-actions .btn { padding: 10px 16px; font-size: 13.5px; min-height: 42px; }
  .detail { font-size: 13.5px; color: var(--text-2); margin-top: 12px; padding-top: 12px; border-top: .8px solid var(--divider); display: grid; gap: 5px; }
  .detail b { color: var(--text); font-weight: 600; }

  /* modal */
  .overlay { position: fixed; inset: 0; background: rgba(0,20,35,.55); display: none; align-items: flex-start; justify-content: center; padding: 40px 16px; overflow-y: auto; z-index: 50; }
  .overlay.open { display: flex; }
  .modal { background: #fff; border-radius: 20px; width: 100%; max-width: 520px; padding: 26px; }
  .modal h3 { font-size: 20px; font-weight: 900; letter-spacing: -.4px; margin-bottom: 20px; }
  .modal-actions { display: flex; gap: 10px; margin-top: 6px; }
  .modal-actions .btn { flex: 1; justify-content: center; }

  .empty { text-align: center; padding: 60px 20px; color: var(--text-2); }
  .empty .big { font-size: 44px; margin-bottom: 12px; }
  .toast { position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%); background: var(--primary); color: #fff; padding: 13px 22px; border-radius: 12px; font-size: 14px; font-weight: 600; box-shadow: 0 8px 24px rgba(0,0,0,.25); opacity: 0; transition: opacity .25s; pointer-events: none; z-index: 99; }
  .toast.show { opacity: 1; }
  .spinner { border: 2.5px solid rgba(255,255,255,.35); border-top-color: #fff; border-radius: 50%; width: 18px; height: 18px; animation: spin .7s linear infinite; }
  @keyframes spin { to { transform: rotate(360deg); } }
  .hidden { display: none !important; }
  @media (max-width: 560px) { .branch-head { flex-wrap: wrap; } .row-actions { margin-left: 0; width: 100%; } .row-actions .btn { flex: 1; justify-content: center; } }
</style>
</head>
<body>

<!-- LOGIN VIEW -->
<div id="loginView">
  <div class="hero"><div class="hero-inner"><div><h1>HFA Admin</h1><p>Branches control panel</p></div></div></div>
  <div class="login-wrap">
    <div class="card" style="padding:28px">
      <h2>Sign in</h2>
      <p class="sub">Head coach account only</p>
      <div class="err" id="loginErr"></div>
      <label>Email</label>
      <input type="email" id="email" placeholder="Enter email" autocomplete="username">
      <label>Password</label>
      <input type="password" id="password" placeholder="Enter password" autocomplete="current-password">
      <button class="btn btn-primary" style="width:100%;justify-content:center" id="loginBtn" onclick="login()">Sign in</button>
    </div>
  </div>
</div>

<!-- DASHBOARD VIEW -->
<div id="dashView" class="hidden">
  <div class="hero">
    <div class="hero-inner">
      <div><h1>Branches</h1><p id="dashSub">Manage your academy branches</p></div>
      <div class="actions">
        <button class="btn btn-primary" onclick="openForm()">+ Add Branch</button>
        <button class="btn btn-ghost" onclick="logout()">Logout</button>
      </div>
    </div>
  </div>
  <div class="container" id="list"></div>
</div>

<!-- FORM MODAL -->
<div class="overlay" id="formOverlay">
  <div class="modal">
    <h3 id="formTitle">Add Branch</h3>
    <div class="err" id="formErr"></div>
    <label>Branch name *</label>
    <input id="f_name" placeholder="e.g. Maadi">
    <label>Address</label>
    <input id="f_address" placeholder="Street, area, city">
    <label>Phone</label>
    <input id="f_phone" type="tel" placeholder="e.g. 01012345678">
    <label>WhatsApp</label>
    <input id="f_whatsapp" type="tel" placeholder="e.g. 201012345678">
    <div class="helper">Number used for the wa.me chat link — include country code.</div>
    <label>Video link</label>
    <input id="f_video" type="url" placeholder="YouTube link shown embedded in the app">
    <label>Practice times</label>
    <textarea id="f_practice" placeholder="Sat 4-6 PM, Mon 4-6 PM, Wed 4-6 PM"></textarea>
    <div class="helper">Separate entries with commas — each shows as a bullet in the app.</div>
    <div class="modal-actions">
      <button class="btn btn-outline" onclick="closeForm()">Cancel</button>
      <button class="btn btn-primary" id="saveBtn" onclick="save()">Save</button>
    </div>
  </div>
</div>

<!-- DELETE MODAL -->
<div class="overlay" id="delOverlay">
  <div class="modal">
    <h3>Delete branch?</h3>
    <p style="color:var(--text-2);font-size:14.5px;margin-bottom:22px">This will permanently delete <b id="delName"></b> and its chat threads. This cannot be undone.</p>
    <div class="modal-actions">
      <button class="btn btn-outline" onclick="closeDel()">Cancel</button>
      <button class="btn btn-danger" id="delBtn" onclick="doDelete()">Delete</button>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
const API = '';
let token = localStorage.getItem('hfa_admin_token') || '';
let branches = [];
let editId = null, deleteId = null;

const $ = id => document.getElementById(id);
const esc = s => (s ?? '').toString().replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function toast(msg) {
  const t = $('toast'); t.textContent = msg; t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}
function showErr(id, msg) { const e = $(id); e.textContent = msg; e.style.display = 'block'; }
function hideErr(id) { $(id).style.display = 'none'; }

async function api(path, opts = {}) {
  const res = await fetch(API + path, {
    ...opts,
    headers: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': 'Bearer ' + token } : {}), ...(opts.headers || {}) },
  });
  let data = null;
  try { data = await res.json(); } catch (_) {}
  if (!res.ok) {
    if (res.status === 401) { logout(); throw new Error('Session expired — sign in again'); }
    throw new Error((data && data.detail) ? data.detail : 'Request failed (' + res.status + ')');
  }
  return data;
}

async function login() {
  hideErr('loginErr');
  const btn = $('loginBtn');
  btn.disabled = true; btn.innerHTML = '<div class="spinner"></div>';
  try {
    const data = await api('/auth/login', { method: 'POST', body: JSON.stringify({ email: $('email').value.trim(), password: $('password').value }) });
    if (data.user.role !== 'head_coach') throw new Error('Only the head coach can access this dashboard');
    token = data.token;
    localStorage.setItem('hfa_admin_token', token);
    $('dashSub').textContent = 'Signed in as ' + data.user.name;
    showDash();
  } catch (e) {
    showErr('loginErr', e.message);
  } finally {
    btn.disabled = false; btn.textContent = 'Sign in';
  }
}

function logout() {
  token = ''; localStorage.removeItem('hfa_admin_token');
  $('dashView').classList.add('hidden');
  $('loginView').classList.remove('hidden');
}

function showDash() {
  $('loginView').classList.add('hidden');
  $('dashView').classList.remove('hidden');
  load();
}

async function load() {
  $('list').innerHTML = '<div class="empty">Loading…</div>';
  try {
    branches = await api('/branches/');
    render();
  } catch (e) {
    $('list').innerHTML = '<div class="empty"><div class="big">⚠</div>' + esc(e.message) + '</div>';
  }
}

function chip(label, on) { return '<span class="chip ' + (on ? 'on' : 'off') + '">' + label + (on ? ' ✓' : ' —') + '</span>'; }

function render() {
  if (!branches.length) {
    $('list').innerHTML = '<div class="empty"><div class="big">🏊</div>No branches yet.<br><br><button class="btn btn-primary" onclick="openForm()">+ Add your first branch</button></div>';
    return;
  }
  $('list').innerHTML = branches.map(b => `
    <div class="card">
      <div class="branch-head">
        <div class="icon-badge">📍</div>
        <div style="flex:1;min-width:0">
          <div class="branch-title">${esc(b.name)}</div>
          ${b.address ? '<div class="branch-sub">' + esc(b.address) + '</div>' : ''}
          <div class="chips">
            ${chip('Phone', !!b.phone)}${chip('WhatsApp', !!b.whatsapp)}${chip('Video', !!b.video_url)}${chip('Schedule', !!b.practice_days)}
          </div>
        </div>
        <div class="row-actions">
          <button class="btn btn-outline" onclick="openForm(${b.id})">Edit</button>
          <button class="btn btn-danger" onclick="openDel(${b.id})">Delete</button>
        </div>
      </div>
      ${(b.phone || b.whatsapp || b.practice_days) ? `<div class="detail">
        ${b.phone ? '<div><b>Phone:</b> ' + esc(b.phone) + '</div>' : ''}
        ${b.whatsapp ? '<div><b>WhatsApp:</b> ' + esc(b.whatsapp) + '</div>' : ''}
        ${b.practice_days ? '<div><b>Practice:</b> ' + esc(b.practice_days) + '</div>' : ''}
      </div>` : ''}
    </div>`).join('');
}

function openForm(id) {
  editId = id || null;
  const b = id ? branches.find(x => x.id === id) : {};
  $('formTitle').textContent = id ? 'Edit Branch' : 'Add Branch';
  $('f_name').value = b.name || '';
  $('f_address').value = b.address || '';
  $('f_phone').value = b.phone || '';
  $('f_whatsapp').value = b.whatsapp || '';
  $('f_video').value = b.video_url || '';
  $('f_practice').value = b.practice_days || '';
  hideErr('formErr');
  $('formOverlay').classList.add('open');
}
function closeForm() { $('formOverlay').classList.remove('open'); }

async function save() {
  hideErr('formErr');
  const name = $('f_name').value.trim();
  if (!name) { showErr('formErr', 'Branch name is required'); return; }
  const body = {
    name,
    address: $('f_address').value.trim() || null,
    phone: $('f_phone').value.trim() || null,
    whatsapp: $('f_whatsapp').value.trim() || null,
    video_url: $('f_video').value.trim() || null,
    practice_days: $('f_practice').value.trim() || null,
  };
  const btn = $('saveBtn');
  btn.disabled = true; btn.innerHTML = '<div class="spinner"></div>';
  try {
    if (editId) await api('/branches/' + editId, { method: 'PUT', body: JSON.stringify(body) });
    else await api('/branches/', { method: 'POST', body: JSON.stringify(body) });
    closeForm();
    toast(editId ? 'Branch updated' : 'Branch added');
    load();
  } catch (e) {
    showErr('formErr', e.message);
  } finally {
    btn.disabled = false; btn.textContent = 'Save';
  }
}

function openDel(id) {
  deleteId = id;
  $('delName').textContent = (branches.find(x => x.id === id) || {}).name || '';
  $('delOverlay').classList.add('open');
}
function closeDel() { $('delOverlay').classList.remove('open'); }

async function doDelete() {
  const btn = $('delBtn');
  btn.disabled = true; btn.innerHTML = '<div class="spinner"></div>';
  try {
    await api('/branches/' + deleteId, { method: 'DELETE' });
    closeDel();
    toast('Branch deleted');
    load();
  } catch (e) {
    closeDel();
    toast(e.message);
  } finally {
    btn.disabled = false; btn.textContent = 'Delete';
  }
}

// Enter key submits login
$('password').addEventListener('keydown', e => { if (e.key === 'Enter') login(); });
// Close modals on backdrop click
document.querySelectorAll('.overlay').forEach(o => o.addEventListener('click', e => { if (e.target === o) o.classList.remove('open'); }));

// Auto-login if token still valid
if (token) {
  api('/branches/').then(() => showDash()).catch(() => logout());
}
</script>
</body>
</html>"""


@router.get("/admin", response_class=HTMLResponse)
def admin_dashboard():
    return ADMIN_HTML
