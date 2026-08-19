const statusEl = document.getElementById('status');
const registerBtn = document.getElementById('registerBtn');
const unlockBtn = document.getElementById('unlockBtn');
const lockBtn = document.getElementById('lockBtn');
const lockAgainBtn = document.getElementById('lockAgainBtn');
const lockScreen = document.getElementById('lockScreen');
const homeScreen = document.getElementById('homeScreen');

const KEY = 'faceid-web-demo-credential-id';

function setStatus(msg, type='') {
  statusEl.textContent = msg;
  statusEl.className = 'status' + (type ? ' ' + type : '');
}

function supported() {
  return !!(window.PublicKeyCredential && navigator.credentials);
}

function randomBytes(len=32) {
  return crypto.getRandomValues(new Uint8Array(len));
}

function toBase64Url(bytes) {
  let s = '';
  bytes.forEach(b => s += String.fromCharCode(b));
  return btoa(s).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}

function fromBase64Url(value) {
  value = value.replace(/-/g,'+').replace(/_/g,'/');
  while (value.length % 4) value += '=';
  const bin = atob(value);
  return Uint8Array.from(bin, c => c.charCodeAt(0));
}

async function registerCredential() {
  if (!supported()) {
    setStatus('Este navegador não suporta Passkeys/WebAuthn.', 'error');
    return;
  }

  try {
    setStatus('Abrindo autenticação do aparelho...');

    const credential = await navigator.credentials.create({
      publicKey: {
        challenge: randomBytes(32),
        rp: { name: 'Face ID Web Demo', id: location.hostname },
        user: {
          id: randomBytes(16),
          name: 'teste@faceid.local',
          displayName: 'Usuário de teste'
        },
        pubKeyCredParams: [
          { type: 'public-key', alg: -7 },
          { type: 'public-key', alg: -257 }
        ],
        authenticatorSelection: {
          authenticatorAttachment: 'platform',
          residentKey: 'preferred',
          userVerification: 'required'
        },
        timeout: 60000,
        attestation: 'none'
      }
    });

    localStorage.setItem(KEY, toBase64Url(new Uint8Array(credential.rawId)));
    setStatus('Credencial cadastrada. Agora toque em “Entrar com Face ID”.', 'ok');
  } catch (err) {
    setStatus('Cadastro cancelado ou indisponível: ' + (err.name || 'erro'), 'error');
  }
}

async function unlock() {
  if (!supported()) {
    setStatus('Este navegador não suporta Passkeys/WebAuthn.', 'error');
    return;
  }

  const saved = localStorage.getItem(KEY);
  if (!saved) {
    setStatus('Primeiro cadastre a credencial neste aparelho.', 'error');
    return;
  }

  try {
    setStatus('Olhe para o iPhone...');

    await navigator.credentials.get({
      publicKey: {
        challenge: randomBytes(32),
        allowCredentials: [{
          type: 'public-key',
          id: fromBase64Url(saved),
          transports: ['internal']
        }],
        userVerification: 'required',
        timeout: 60000
      }
    });

    lockScreen.classList.add('hidden');
    homeScreen.classList.remove('hidden');
  } catch (err) {
    setStatus('Autenticação cancelada ou falhou: ' + (err.name || 'erro'), 'error');
  }
}

function lock() {
  homeScreen.classList.add('hidden');
  lockScreen.classList.remove('hidden');
  setStatus('Toque em “Entrar com Face ID” para testar novamente.');
}

registerBtn.addEventListener('click', registerCredential);
unlockBtn.addEventListener('click', unlock);
lockBtn.addEventListener('click', lock);
lockAgainBtn.addEventListener('click', lock);
