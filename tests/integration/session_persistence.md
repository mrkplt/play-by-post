# Manual testing plan — Session persistence & 30-day logins

Covers the server-side session store, the per-user salt (`remember_token`), and
month-long remember-me. See REQUIREMENTS "Sessions & staying logged in".

## Preconditions
- App running in production-like mode (or dev with the same config).
- A user account with a valid email.

## 1. Magic-link login issues a persistent login
1. Go to the sign-in page, enter your email, submit.
2. Open the magic-link email and click the link.
3. **Expect:** you land signed in on "Your Games".
4. In the browser dev tools → Application → Cookies, confirm both a
   `_play_by_post_session` cookie and a `remember_user_token` cookie exist, and
   that `remember_user_token` has an **Expires ~30 days** out (not "Session").

## 2. Session is server-side
1. While logged in, inspect the `sessions` table in the primary database:
   `sqlite3 storage/development.sqlite3 'select session_id, updated_at from sessions;'`
   (prod: `/data/production.sqlite3`).
2. **Expect:** a row whose `session_id` corresponds to your session; the cookie
   itself carries only the opaque id, not the session payload.

## 3. Login survives a deploy / restart
1. While logged in, restart the app (`bin/rails restart`, or redeploy the
   container).
2. Reload the app in the browser (do **not** clear cookies).
3. **Expect:** still logged in — no bounce to the sign-in page.
   - If this fails on a real deploy, verify `secret_key_base` is stable across
     deploys (see docs/CONFIGURATION.md — `SECRET_KEY_BASE` must be unset in
     Coolify so the credential is used).

## 4. Login survives a browser restart (remember-me)
1. While logged in, fully quit and reopen the browser.
2. Visit the app.
3. **Expect:** still logged in (the remember-me cookie re-authenticates).

## 5. Sign-out ends the login
1. Open the nav drawer → "Sign Out".
2. **Expect:** redirected to the sign-in page; both `_play_by_post_session` and
   `remember_user_token` cookies are cleared.
3. Sign back in via a new magic link.
4. **Expect:** a fresh login; the user's `remember_token` has been regenerated
   (it is non-nil again).

## 6. Revocation (optional, admin)
1. In a console, rotate a user's token:
   `user.update_column(:remember_token, Devise.friendly_token)`.
2. In that user's still-open browser, make a request.
3. **Expect:** they are signed out (the session's stored salt no longer matches).
