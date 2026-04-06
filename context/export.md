# Game Export — Product Requirements

## Overview

Players and GMs invest significant creative effort in collaborative stories. Currently there is
no way to archive or export that content for safekeeping, printing, or sharing outside the app.

This feature lets any eligible game participant request an export of one game or all their
games. The export is assembled in the background and delivered by email as a time-limited
download link containing a structured zip archive of scenes, posts, characters, and a game
file manifest.

---

## Goals

- Preserve collaborative stories in a portable, human-readable format.
- Deliver value to current and former participants equally (removed players keep access to their history).
- Keep the request flow simple: one button, one email, one download.
- Avoid re-implementing access control — the export must respect the same visibility rules
  already enforced in the app.

## Non-Goals

- Real-time or streaming export; background delivery is acceptable.
- Binary game-file downloads (PDFs, images uploaded by the GM) — a manifest is sufficient.
- Character sheet diff views — full text per version is enough, consistent with v1 of the
  in-app version history.
- Export of other users' personal data (emails, login history).
- Admin-only bulk export of all games on the platform.
- PDF rendering — plain Markdown files are the target format.

---

## User Eligibility

| Member status | Single game export | All-games export |
|---------------|--------------------|-----------------|
| Active        | Yes — full game    | Yes — all active games |
| Removed       | Yes — scenes they participated in only | Yes — same scoping per game |
| Banned        | No                 | No (game excluded from all-games export) |

"Former participant" means `game_members.status = 'removed'`. Banned members (`status = 'banned'`)
have no export access, consistent with their complete access revocation throughout the app.

---

## What Is Exported

### Game Metadata (`README.md`)
- Game name and description
- Export timestamp (UTC)
- Member roster: display name, role (GM / Player), status (Active / Former)
- Scene count (active / resolved)

### Scenes (`scenes/NNN-{scene-title-slug}/`)

**Included for active members:** all scenes (public and private scenes the requester participates in).
**Included for removed members:** only scenes they were a participant in at any point.

Each scene directory contains:

#### `scene_info.md`
- Title, description
- Parent scene title (if any) and relationship
- Participants: display names (and character name if assigned via `scene_participants.character_id`)
- Status: active or resolved
- Created at, resolved at (if resolved)
- Resolution / outcomes text (if resolved)

#### `posts.md`
- All **published** posts in chronological order (drafts excluded)
- Each post formatted as:
  ```
  ## {Author display name}{character context if available} — {timestamp UTC}
  {OOC label if applicable}

  {Markdown content}

  ---
  ```
- OOC posts labeled `[Out of Character]` immediately below the post header
- Posts edited within the edit window noted with `(edited)` next to timestamp

### Characters (`characters/{character-name-slug}/`)

All characters who appeared as a `scene_participants.character_id` reference in any exported
scene, plus all characters belonging to the requesting user in that game.

Each character directory contains:

#### `current_sheet.md`
- Character name, owner display name
- Hidden / archived status
- Current sheet content (plain text, whitespace preserved)

#### `version_history/vNNN-{YYYY-MM-DD}.md`
- One file per `CharacterVersion` record, oldest first
- Each file contains: version number, date, editor display name, full sheet content at that point

### Game File Manifest (`files_manifest.md`)
- Table listing all `GameFile` records: filename, file type, size (human-readable), upload date
- Note that binary files are not included; the game's GM can download them from the app

---

## Archive Structure

```
{game-name-slug}-export-{YYYY-MM-DD}/
  README.md
  files_manifest.md
  scenes/
    001-{scene-title-slug}/
      scene_info.md
      posts.md
    002-{scene-title-slug}/
      scene_info.md
      posts.md
  characters/
    {character-name-slug}/
      current_sheet.md
      version_history/
        v001-{YYYY-MM-DD}.md
        v002-{YYYY-MM-DD}.md
```

Scenes are numbered in creation order (001, 002, …) to preserve narrative sequence.
Scene title slugs are parameterized (e.g. "The Docks at Midnight" → `the-docks-at-midnight`).
Character name slugs follow the same convention.
Collisions in slugs are disambiguated with a numeric suffix (`-2`, `-3`, …).

### All-Games Archive Structure

When exporting all games, each game gets the same structure above as a subdirectory:

```
all-games-export-{YYYY-MM-DD}/
  {game-name-slug}/
    README.md
    files_manifest.md
    scenes/…
    characters/…
  {game-name-slug-2}/
    …
```

---

## Delivery

1. User clicks "Export Game" (or "Export All Games").
2. A confirmation modal explains scope, estimated delivery time ("within a few minutes"), and
   the 24-hour rate limit.
3. User confirms → `ExportJob` is enqueued via Solid Queue.
4. `ExportJob` assembles the zip in memory / temp storage and attaches it via Active Storage.
5. `ExportMailer#export_ready` is delivered: subject "Your [Game Name] export is ready" (or
   "Your export is ready" for all-games), body explains what's included, contains a prominent
   download button linked to a time-limited (7-day) signed Active Storage URL.
6. After 7 days the attachment is purged automatically (Active Storage expiry).
7. If the job fails after retries, `ExportMailer#export_failed` is delivered with a generic
   error message and an invitation to try again.

---

## UI & User Experience

### Single Game Export
- **Trigger:** "Export Game" button on the game view page, visible to all eligible (non-banned)
  participants. Placed in the game actions area near other non-destructive actions.
- Removed members see the button on their read-only game view.
- Button is replaced by a disabled state with tooltip "Export requested — check your email"
  if an export was already requested within the last 24 hours.

### All-Games Export
- **Trigger:** "Export All Games" button on the player profile page or dashboard.
- Exports all games where the user is active or removed (banned games silently excluded).
- Same 24-hour rate limit applies to the all-games request independently of per-game limits.

### Confirmation Modal
Both flows present a modal before enqueueing:
- Title: "Export [Game Name]" / "Export All Games"
- Body: brief description of what's included (scenes, posts, characters, file manifest)
- Note: "You'll receive an email with a download link within a few minutes. The link expires
  after 7 days."
- Rate-limit note if applicable: "You can request one export per game every 24 hours."
- Actions: "Request Export" (primary) / "Cancel"

### Flash / Toast
After confirming: "Export requested — you'll receive an email shortly."
If rate-limited: "An export was already requested recently. You can request again after [time]."

---

## Rate Limiting

- One export request per user per game per 24-hour rolling window.
- All-games counts as one request against a separate all-games limit (also 24 hours).
- Enforced in the controller before enqueueing. A `game_export_requests` table tracks the
  last request timestamp per user+game — a DB table is preferred over a cache-backed counter
  for auditability and cache-flush resilience.
- Rate-limit violations return HTTP 429 in the API and a flash in the UI; no job is enqueued.

---

## Privacy & Data Handling

- Exports contain only data the requesting user already has access to in the app (enforced
  by re-applying the same visibility rules used in views).
- User emails are **not** included anywhere in the export — only display names.
- Banned members' posts and characters remain in the export if they were participants (they
  are historical record), attributed by display name only.
- Zip download URLs are signed Active Storage URLs (time-limited, not guessable).
- Zip files are purged from storage after 7 days.
- Exports are not shared between users; each request generates a unique archive for the
  requesting user.

---

## Success Metrics

- Export requests fulfilled within 2 minutes (P95) for games with ≤ 500 posts.
- Email delivery rate ≥ 99% (same Mailgun infrastructure as existing notifications).
- Zero access-control violations (no content surfaced that the user cannot see in the app).
- User-reported satisfaction: qualitative feedback via support channel.

---

## Open Questions / Future Considerations

- **Incremental exports:** Could offer "export changes since last export" for ongoing games.
  Deferred to a future iteration.
- **Direct PDF rendering:** Markdown is sufficient for v1; a rendered PDF could be a later
  enhancement using a headless browser or a PDF gem.
- **GM admin export:** A GM might want to export the full game including hidden character
  sheets and private scenes they weren't invited to (edge case). Currently the export respects
  standard visibility. Could be a GM-specific scope in a future version.
- **Post images:** Scene and post image attachments are not included in v1 (same rationale as
  game files). A future version could bundle them under a `media/` directory.
