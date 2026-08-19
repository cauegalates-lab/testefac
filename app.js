const statusEl = document.getElementById('status');
const loginBtn = document.getElementById('loginBtn');
const registerBtn = document.getElementById('registerBtn');
const success = document.getElementById('success');
const backBtn = document.getElementById('backBtn');

const savedCredentialKey = 'faceid-demo-credential-id';

function setStatus(message, type='') {
  statusEl.textContent = message;
  statusEl.className = 'status' + (type ? ' ' + type : '');
}

function randomBytes(length = 32) {
  return crypto.getRandomValues(new Uint8Array(length));
}

function toBase64Url(bytes) {
  let binary = '';
  bytes.forEach(b => binary += String.fromCharCode(b));
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/,'');
}

function fromBase64Url(value) {
  value = value.replace(/-/g, '+').replace(/_/g, '/');
  while (value.length % 4) value += '=';
  const binary = atob(value);
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}

function supported() {
  return !!(window.PublicKeyCredential && navigator.credentials);
}

async function registerPasskey() {
  if (!supported()) {
    setStatus('Este navegador não suporta Passkeys/WebAuthn.', 'error');
    return;
  }

  try {
    setStatus('Abrindo autenticação do aparelho...');

    const credential = await navigator.credentials.create({
      publicKey: {
        challenge: randomBytes(32),
        rp: { name: 'Face ID Demo', id: location.hostname },
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

    localStorage.setItem(savedCredentialKey, toBase64Url(new Uint8Array(credential.rawId)));
    setStatus('Face ID/Passkey cadastrado. Agora toque em Entrar com Face ID.', 'ok');
  } catch (error) {
    setStatus('Cadastro cancelado ou não disponível: ' + (error.name || 'erro'), 'error');
  }
}

async function loginWithPasskey() {
  if (!supported()) {
    setStatus('Este navegador não suporta Passkeys/WebAuthn.', 'error');
    return;
  }

  const savedId = localStorage.getItem(savedCredentialKey);
  if (!savedId) {
    setStatus('Primeiro toque em “Cadastrar Face ID neste aparelho”.', 'error');
    return;
  }

  try {
    setStatus('Verificando identidade...');

    await navigator.credentials.get({
      publicKey: {
        challenge: randomBytes(32),
        allowCredentials: [{
          type: 'public-key',
          id: fromBase64Url(savedId)
        }],
        userVerification: 'required',
        timeout: 60000
      }
    });

    success.hidden = false;
    setStatus('Acesso confirmado.', 'ok');
  } catch (error) {
    setStatus('Autenticação cancelada ou falhou: ' + (error.name || 'erro'), 'error');
  }
}

registerBtn.addEventListener('click', registerPasskey);
loginBtn.addEventListener('click', loginWithPasskey);
backBtn.addEventListener('click', () => success.hidden = true);
