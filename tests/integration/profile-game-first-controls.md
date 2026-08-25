# Profile: game-first control plane ("Your Games" section)

## What changed

The profile's three feature-first per-game sections — **RSS Feeds**, **API tokens**,
and **Fund AI for your games** — are replaced by one game-first section, **Your Games**:
one card per game membership, each card holding that game's RSS feed control, API
token control, and (when the viewer has a BYOK key) AI funding toggles. The profile
keeps its identity/preference sections (Display Name, Avatar, Account, AI, Export)
unchanged.

The "View API documentation" link moves from the old "API tokens" section label to
the "Your Games" section label.

## Setup

- Signed-in user with a display name.
- Two games the user belongs to (member of one, GM of another — the section does
  not distinguish roles).
- A second user for the zero-games case (fresh account, no memberships).

## Scenarios

### 1. Section layout
- Visit `/profile`.
- Expect a **YOUR GAMES** section label with the "View API documentation" link
  inline on the label row (full navigation, not Turbo).
- Expect **no** "RSS FEEDS", "API TOKENS", or "FUND AI FOR YOUR GAMES" sections.
- Expect one card per game, each headed by the game name, containing an
  "RSS feed" row and an "API token" row.
- With no BYOK key on the account: no "Fund AI" row in any card.

### 2. RSS feed lifecycle inside a card
- In game A's card, click **Create feed** → a masked secret field appears in the
  same card, labelled Feed URL, with Show/Copy/Revoke.
- **Show** reveals the full feed URL containing the token.
- **Revoke** removes it; the card returns to the **Create feed** button.
- Game B's card is unaffected throughout.

### 3. API token lifecycle inside a card
- In game A's card, click **Create token** → masked secret field with the raw
  bearer token behind Show; Revoke returns the row to **Create token**.

### 4. AI funding follows key presence
- Add a BYOK key (or use a user that has one): every game card gains a
  **Fund AI** row with a toggle per pool-fundable feature (today: Scene summaries).
- Toggling on creates the `GameKeyAuthorization` for that game; toggling off
  removes it. State is per game — funding game A does not light up game B.
- Remove the key: the Fund AI rows disappear from all cards **in place** (the
  BYOK delete response re-renders the section via Turbo Stream — no reload).

### 5. Zero games
- As the fresh user, visit `/profile`: the Your Games section shows the
  join-a-game empty text instead of cards.

### 6. Both viewports
- Repeat scenario 1 at mobile (<1024px) and desktop (≥1024px) widths — the cards
  render and the secret fields stay within the card at both.
