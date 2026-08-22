# BYOK key: delete + neutral-state UX

Fixes the terrible key-save UX on the Profile screen. The saved state used to
render a password field with a "Replace key" button — implying the key could be
retrieved and re-pasted. It can't. This replaces that with a plain "a key is
saved" line and a **Delete** button, and discards the "Replace" affordance
entirely.

## The three states of the BYOK control

| State | Backing data | UI |
|---|---|---|
| Neutral | no `EncryptedValue` | "Set up encryption" button (POST create) |
| Ready, unsealed | `EncryptedValue` + keypair, `sealed_value` nil | paste-a-key form, "Save key" |
| Key present | `EncryptedValue` with `sealed_value` | "A key is saved." + **Delete** button — no password field, no paste form |

## Delete is a full teardown

Delete returns the control to the **neutral** state — it destroys the whole
`EncryptedValue` (and, via `dependent: :destroy`, its `PublicKey`), and
explicitly destroys the worker-database `PrivateKey` (no association cascade
spans the `connects_to` boundary). Adding a key again therefore runs "Set up
encryption" and generates a **brand-new keypair** — re-sealing against the old
keypair is not a supported action.

## Manual verification (both viewports)

1. As a user with a profile, visit `/profile`.
2. Neutral: see "Set up encryption". Click it → keypair generates, page shows
   the paste form.
3. Paste a key, Save → status reads "A key is saved.", a **Delete** button is
   shown, and there is **no** password field on screen.
4. Click Delete → returns to the neutral "Set up encryption" state; the
   `EncryptedValue`, `PublicKey`, and `PrivateKey` rows are all gone.
5. Set up encryption again → a **new** keypair (different fingerprint) is
   generated.
