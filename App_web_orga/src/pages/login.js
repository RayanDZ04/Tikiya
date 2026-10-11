import { authApi, auth, TwoFactorRequired } from '../api.js';

export function renderLogin(onSuccess) {
  const html = `
    <div class="login-wrap">
      <form class="login-card" id="loginForm" autocomplete="on">
        <div class="login-logo">Tikiya<span class="bang">!</span> <span class="pro">PRO</span></div>
        <div class="login-sub">Espace organisateur</div>
        <div id="loginError"></div>

        <div class="field" id="emailField">
          <label for="email">Adresse e-mail</label>
          <input type="email" id="email" required placeholder="vous@exemple.com" />
        </div>
        <div class="field" id="passwordField">
          <label for="password">Mot de passe</label>
          <input type="password" id="password" required placeholder="••••••••" />
        </div>
        <div class="field" id="totpField" style="display:none;">
          <label for="totp">Code de vérification (2FA)</label>
          <input type="text" id="totp" inputmode="numeric" maxlength="6" class="code-input" placeholder="000000" />
        </div>

        <button type="submit" class="btn btn-primary" id="loginBtn">Se connecter</button>
      </form>
    </div>
  `;

  function bind(root) {
    const form = root.querySelector('#loginForm');
    const errEl = root.querySelector('#loginError');
    const btn = root.querySelector('#loginBtn');
    const totpField = root.querySelector('#totpField');
    let twoFaMode = false;

    const showError = (msg) => {
      errEl.innerHTML = `<div class="login-error">${msg}</div>`;
    };

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      errEl.innerHTML = '';
      const email = root.querySelector('#email').value.trim();
      const password = root.querySelector('#password').value;
      const totp = root.querySelector('#totp').value.trim();

      btn.disabled = true;
      btn.textContent = 'Connexion…';
      try {
        const data = await authApi.login(email, password, twoFaMode ? totp : undefined);
        const user = data.user || {};
        const role = user.role || '';
        if (role !== 'organisateur' && role !== 'admin') {
          showError('Cet espace est réservé aux organisateurs.');
          auth.clear();
          return;
        }
        const token = data.tokens?.access_token;
        if (!token) { showError('Réponse inattendue du serveur.'); return; }
        auth.setSession(token, user);
        onSuccess();
      } catch (err) {
        if (err instanceof TwoFactorRequired) {
          twoFaMode = true;
          totpField.style.display = 'block';
          root.querySelector('#totp').focus();
          showError('Entrez le code à 6 chiffres de votre application d\'authentification.');
        } else {
          showError(err.message || 'Échec de la connexion.');
        }
      } finally {
        btn.disabled = false;
        btn.textContent = twoFaMode ? 'Valider le code' : 'Se connecter';
      }
    });
  }

  return { html, bind };
}
