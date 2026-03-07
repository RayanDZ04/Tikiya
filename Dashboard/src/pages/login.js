import { authApi, auth } from '../api.js';

export async function renderLogin(onSuccess) {
  return {
    html: `
      <div class="login-wrap">
        <div class="login-card">
          <div class="login-logo">
            <div class="brand">Tikiya<span style="color:var(--bleu-cyan)">!Boss</span></div>
            <div class="subtitle">Interface d'administration</div>
          </div>
          <form class="login-form" id="loginForm" autocomplete="off">
            <div class="field-group">
              <label for="email">Adresse e-mail</label>
              <input type="email" id="email" placeholder="admin@tikiya.dz" required autocomplete="username" />
            </div>
            <div class="field-group">
              <label for="password">Mot de passe</label>
              <input type="password" id="password" placeholder="••••••••" required autocomplete="current-password" />
            </div>
            <button type="submit" class="btn-primary" id="loginBtn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
              Se connecter
            </button>
            <div id="loginError" class="login-error" style="display:none;"></div>
          </form>
        </div>
      </div>
    `,
    bind(root) {
      const form  = root.querySelector('#loginForm');
      const btn   = root.querySelector('#loginBtn');
      const errEl = root.querySelector('#loginError');

      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email    = root.querySelector('#email').value.trim();
        const password = root.querySelector('#password').value;
        btn.disabled = true;
        btn.textContent = 'Connexion…';
        errEl.style.display = 'none';

        try {
          const data = await authApi.login(email, password);
          const token = data?.tokens?.access_token;
          const user  = data?.user;

          if (!token) throw new Error('Token manquant');
          if (user?.role !== 'admin') throw new Error('Accès refusé — compte administrateur requis');

          auth.setSession(token, user);
          onSuccess();
        } catch (err) {
          errEl.textContent = err.message || 'Erreur de connexion';
          errEl.style.display = 'block';
          btn.disabled = false;
          btn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg> Se connecter`;
        }
      });
    }
  };
}
