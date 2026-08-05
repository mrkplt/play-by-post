# Play-by-Post TTRPG — Product Requirements

Asynchronous tabletop RPG platform. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

For technology stack, domain model, codebase conventions, and development workflow see [CLAUDE.md](../.claude/CLAUDE.md).

---

## Authentication & Accounts

- Authentication is magic link only — no passwords
- A magic login link is valid for 1 day after it is sent; links older than that are rejected
- New users arrive via invitation magic links; there is no standalone signup page
- A magic link from an invitation creates a new account or links to an existing one
- After first login, users must set a display name before using the app
- Display names are required and shown throughout the app for authorship attribution

### Sessions & staying logged in

- **A login lasts 30 days.** Signing in via a magic link sets a persistent remember-me cookie (`config.remember_for = 30.days`) and a server-side session that expires after 30 days. The login survives browser restarts and app deploys — it is not tied to the browser session.
- **Sessions are stored server-side** (`activerecord-session_store`): the session payload lives in a `sessions` table in the primary database (on the mounted `/data` volume in production), and the cookie holds only an opaque session id. Because the table is on the persistent volume, sessions survive deploys and container restarts.
- **Every user has a `remember_token`**, generated on create. It is the user's `authenticatable_salt` and the value behind the remember-me cookie. This gives the passwordless model a real per-user salt (Devise's default is nil without a password), so a session can be validated and revoked: rotating a user's `remember_token` invalidates that user's sessions and remember-me cookie.
- **Sign-out** clears the current session and the remember-me cookie, and (via `expire_all_remember_me_on_sign_out`) drops the user's `remember_token`; the next magic-link login regenerates it.
- One-time effect on first deploy of this behaviour: introducing a non-nil salt invalidates any pre-existing session cookie signed against the old (nil) salt, so users logged in at that moment are asked to sign in once more.

---

## Navigation & Layout (mobile-first redesign)

- The interface is mobile-first: each screen is a full-bleed frame with a dark header bar over a light body. Dark surface `#2b2d31` (header bars) / `#1a1b1e` (nav drawer); gold accent `#c8a96e`. All colours, radii, and greys are defined once as Tailwind `@theme` tokens and consumed by ViewComponents — no per-screen hex.
- **Global navigation is a slide-in drawer** opened by the hamburger (☰) in each screen's header. The drawer has a fixed profile chip (avatar + display name + "View Profile") at the top, a scrollable list of the player's games in the middle, and pinned "Send Feedback" / "Account Settings" / "Sign Out" at the bottom. Only the games list scrolls; the header and footer stay fixed.
  - Each drawer game row shows a status icon: a crown (♛) for games the viewer GMs, a moon (☾) for a former/removed game, or a plain marker for an ordinary player game. The current game's row is highlighted. Banned games never appear.
- **Icon tap targets** (hamburger, gear, back, OOC checkbox) are sized to a 44px-tall touch target minimum.
- **Attention glow**: interactive cards/rows carry two distinct states — a persistent gold glow (`is-hot`) that is data-driven ("this has unread/new activity") and a lighter hover glow (affordance, "this is clickable"). These are separate states, not one effect at two opacities.
- The UI is built component-first: a shared `MobileFrameComponent` scaffold (header / body / footer slots), `Ui::*` primitives (Avatar, ToggleSwitch, SectionLabel, SettingsRow, IconButton, PillTabs, Badge), and `Shared::*` composed components (GameHeader, NavDrawer, GameCard, SceneCard, RosterRow, PostItem, PostComposer). Screens are assembled purely by composing these components.
- **Desktop rendering**: the same components adapt to wider viewports rather than being redesigned. On phones and tablets (<1024px) the frame keeps its mobile behaviour — full-bleed on phones, a hamburger-opened slide-in nav drawer throughout. At desktop widths (≥1024px) the layout becomes a two-pane website: the nav drawer **docks open as a permanent left rail** (its backdrop and the hamburger are hidden, since navigation is always visible), and each screen's frame becomes the page — a full-width dark top bar (still carrying the title, crown, gear, pill tabs, and any back-arrow) over a light content area whose body is a centered, capped-width reading column. This is purely a responsive CSS treatment (media query in `sidebar_component.css`); no per-screen markup differs between mobile and desktop.

---

## Feedback

- A "Send Feedback" control is pinned in the nav-drawer footer, available on every authenticated screen (both the mobile overlay drawer and the docked desktop rail).
- Clicking it opens a modal that collects the feedback: a free-form textarea, a Submit, and a Cancel. The modal dismisses on Cancel, backdrop click, or Escape.
- Submitting saves a `Feedback` record capturing **who submitted it** (the signed-in user) and **the URL of the page they were on** when they opened the modal (captured client-side and carried in a hidden field). The body is required; a blank submission is rejected.
- The modal **submits in place via fetch — it never navigates the page**. On success the modal swaps to an in-place "Thanks for your feedback!" confirmation with a Close button, so the user stays exactly where they were; on failure an inline error is shown and the form is preserved. The endpoint answers with a bare status (`201`/`422`), not a redirect or re-render.
- The modal is rendered as a sibling of the drawer (not inside it), so its fixed-position overlay spans the viewport rather than being clamped to the off-screen drawer on mobile.
- Any signed-in user may submit feedback (`FeedbackPolicy#create?`); there is no membership or ownership gate. Feedback records belong to the submitting user and are removed with that user (`dependent: :destroy`); they are not tied to a game and so are outside the game-purge flow.
- "Feedback" is a mass noun here — its plural is "feedback" (registered as uncountable), so the table is `feedback`, the association is `has_many :feedback`, and the route is a singular `resource :feedback`.

---

## Player Dashboard

- Landing page after login shows all games the player belongs to, as cards, on a light body under a "Your Games" header (gold title, hamburger to open the drawer). A pinned "+ New Game" button sits in the footer.
- Each game card shows: game name (with a crown ♛ when the viewer is GM of that game), the player's primary character name as text, number of active scenes, and a persistent attention glow if anything changed since last login
- Players with multiple characters see their primary character name with a "+N" suffix for additional characters
- Clicking a game card navigates to the game view
- Removed players see their game with a dormant treatment: a blue tint, a moon (☾) indicator, and "Not currently active" instead of a scene count
- Banned players do not see the game at all

---

## Game Creation

- Any logged-in user can create a new game
- The New Game screen uses the app's mobile-frame chrome (back-arrow header, component-driven form), not a bare form
- Game creation requires a name; description is optional
- Game creator automatically becomes the Game Master (GM)
- Game creation requires a confirmation step before submission
- After creation, the GM lands on the game view

---

## Player Profile

- Reached from the nav drawer's "Account Settings" / "View Profile". Uses the settings-row pattern under a back-arrow header.
- Sections: Display Name (with Edit), Account (email; a "Hide OOC by default" toggle bound to the profile-level `hide_ooc` preference), RSS Feed Token (rotate/revoke, or generate), and Export ("Export All Games" with a last-export notice)
- Users can edit their display name from the edit page
- The Profile page deliberately does **not** list the player's games — that list lives in the nav drawer, to avoid duplication

---

## Game View

- The game area is a single page (`games#show`) with four **pill tabs in the dark header — Scenes / Roster / Files / Pages — switched client-side** (no page navigation). The header shows a hamburger (opens the nav drawer), a GM crown (only when the viewer is GM), the game title, and a gear (Game Settings, any viewer with game access — GM, active player, or removed player). The active tab is deep-linkable via the URL hash.
- **Scenes tab**: active (unresolved) scenes as cards showing just title + participant count (plus parent/child links where threaded), most recent first, with an attention glow on scenes with new activity. Below: an "In Active Scenes" roster preview (the GM as a person with a crown, then characters and the scene they're in — never a banned player), and a "New Scene" action (GM).
- **Roster tab**: a search field, the character list (avatar, name, "Played by {player}"; a removed player's row is dimmed with a "Removed" badge), a "New Character" action, a "N inactive characters hidden" note, and — GM only — a "Banned · GM only" section (blue-tinted, each row with an Unban action) plus the invite controls: an "Invite a Player" (email + Invite) form and a "Pending Invitations" list (email + "Sent X ago" + Cancel). Inviting or cancelling returns the GM to the Roster tab. Inactive (archived) characters are hidden by default.
- **Files tab**: the file gallery (see Game-Level File Store). GM sees the upload form.
- **Pages tab**: an in-page index of the game's pages (title → page), alphabetised by title, with a "New Page" action shown to the GM only (see Game Pages).
- The gear is shown to any non-banned member (GM, active, or removed) and opens Game Settings.

---

## Game Settings

- Reached via the gear (⚙) in the game header — open to any non-banned member, not just the GM. Uses the settings-row pattern under a back-arrow header.
- GM-only sections (hidden entirely for non-GM viewers): Game Details (the game name and its description — the description is rendered as markdown, with single newlines shown as line breaks — with an Edit link opening the Edit Game screen; a blank description shows a "No description yet." placeholder), Members (name + character + Remove/Ban, where Remove is neutral and Ban is red and carries its own more serious confirmation), Game Preferences (an "AI Scene Summaries" toggle switch), and Danger Zone (game deletion — see below). Inviting players lives on the game Roster tab, not here.
- The Edit Game screen (reached from Game Details) uses the same mobile-frame/back-arrow chrome as the rest of the app: a name/description form plus the Post Images, Character Sheets, AI Scene Summaries, and Manage Players controls. Saving the name/description form returns to the Game Settings screen.
- Export section (all non-banned members, GM and non-GM alike): a "This game" row with an "Export Game" action and the last-export notice, same as the profile-level export.
- Non-members and banned members are redirected away with an access alert; this is the only guard on the page itself — GM-only content is scoped by conditionally rendering, not by a separate access check.

### Invitations
- GM invites players by email
- Invited player receives a magic link email; no existing account required
- GM can view all pending invitations
- GM can cancel or resend a pending invitation
- Invitation acceptance creates or links the player's account and adds them to the game

### Player Removal (amicable departure)
- GM can remove a player from a game
- Removed players retain read-only access to the game, game files, and all scenes they participated in
- Removed players can view their own character sheet (read-only)
- Removed players cannot post, create scenes, or be added to new scenes
- Removed players no longer receive notifications
- The game remains on the removed player's dashboard with a dormant "Former" treatment (blue tint, moon ☾ icon, "Not currently active"); it also appears in the nav drawer with a moon icon
- The character roster shows a "Removed" badge on the player's row (dimmed)

### Player Banning (adversarial, GM's discretion)
- GM can ban a player — distinct from removal, with a separate confirmation that communicates permanent access revocation
- Banned players lose all access: game, scenes, posts, characters, files, everything
- The game disappears from the banned player's dashboard entirely
- Banned players no longer receive notifications
- The character roster shows a "Banned" status visible only to the GM

### Game Deletion (GM only)

- Only the game's GM (its owner) sees the Danger Zone "Delete Game" control, and only the GM may delete (`GamePolicy#destroy?`).
- Deletion requires an explicit confirmation: a modal that the GM must confirm by typing the game's exact name; the destructive button stays disabled until the typed text matches. The game name is shown in quotes in the modal copy (heading and the "type to confirm" instruction). Matching ignores surrounding whitespace on both the typed text and the stored name, so a game whose name has leading/trailing spaces is still confirmable. It is framed as permanent — the copy makes no promise of recovery.
- Deletion is **two-phase (soft delete, then scheduled purge)**:
  - **Phase 1 — soft delete (immediate).** The GM's action stamps the game's `deleted_at`. From that moment the game is hidden everywhere — it disappears from the dashboard and the nav drawer, and any direct link to the game or its scenes/posts/files resolves as not-found. This is enforced by a model `default_scope` (`deleted_at IS NULL`), so every lookup, through-association, and export enumeration is filtered without a per-call-site guard. There is no restore UI; the window is purely a safety buffer.
  - **Phase 2 — purge (after a 7-day retention window).** A daily recurring job (`GamePurgeSweepJob`) scans for games whose `deleted_at` is older than the retention window and enqueues one `GamePurgeJob` per game. The purge does **not** rely on association cascades or Active Storage's fire-and-forget `purge_later`: it collects and deletes the game's artifacts and records explicitly. Every stored artifact (post images, scene images, uploaded game files, export archives) is purged from storage within the job, and every dependent record (scenes, posts and reads, participants, summaries, notification preferences, characters and their version history, game files, pages, invitations, memberships, and export requests) is deleted child-first, in batches, ending with the game row. The sweep and purge read past the default scope via `unscoped`.
- Retention is 7 days (`GamePurgeSweepJob::RETENTION`), measured from `deleted_at`; a game deleted exactly at the cutoff is purged, one a second newer is not.

---

## Scenes

### Scene List Behaviour
- Scenes ordered most recent first (descending timestamp)
- Scenes sharing the same parent scene are grouped on the same row (parallel branches)
- Private scenes visible only to participants and the GM
- Resolved scenes displayed separately from active scenes
- The game view lists only active scenes; a "View all scenes" link on the game view opens the All Scenes view (the full scene tree, including resolved scenes), available to every viewer with game access

### Quick Scene (from scene view)
- Creates a new scene inheriting all participants and parent from the current scene
- Minimal form: title only, with the inherited participants and parent carried in hidden fields
- Private flag inherited from the parent scene
- Intended for continuing the narrative with the same group

### New Scene (from scene view or game view)
- The New Scene / Quick Scene screen follows the mobile-first component system: a `MobileFrameComponent` scaffold, a back-arrow `PageHeaderComponent` (titled "New Scene" or "Quick Scene"), and the form rendered by `Shared::SceneFormComponent` using design tokens — no bespoke screen markup
- Full form: title, participant selection, parent scene, private flag, optional image
- When entered from a scene view: pre-populates participants and parent from that scene (GM can change)
- When entered from the game view: starts with the full active player list, no parent pre-selected
- The GM is always included as a participant and cannot be removed
- A scene with only the GM as participant is valid (narration-only)
- Scenes can have one parent or no parent; branching is allowed, merging is not
- Parent scene dropdown includes both active and resolved scenes

### Joining an Existing Scene
- An active game member who is not a participant in a scene can join it themselves
- Join is not available on private scenes or resolved scenes
- The GM cannot join scenes this way (they are always a participant)

### Scene Resolution
- Only the GM can resolve (close) a scene via an "End Scene" action
- Resolution is final and at the GM's sole discretion; players cannot vote or approve
- Resolution presents an optional outcomes text field (what happened, what was gained/lost)
- Resolved scenes display their outcomes prominently
- All scene participants receive a resolution notification email
- The scene toolbar (actions menu) is hidden after a scene is resolved

---

## Scene View & Posts

- Posts are long-form and flat within a scene (linear thread, not nested replies), rendered forum/manuscript-style: each post is a full-width card with the author's avatar monogram, name, and timestamp floated to one side so the (often multi-paragraph) body wraps around them. The GM's avatar is dark; players' are gold.
- Each post shows: author display name, timestamp, markdown-rendered body (≥16px for readability), optional image
- Posts can be marked Out-of-Character (OOC); OOC posts are visually **quiet** — a light blue tint (same family as the retired/removed tint) with a compact "OUT OF CHARACTER" label and slightly smaller text — not a loud banner
- Posts with unread/new activity carry the persistent attention glow
- The scene header carries a **"Hide OOC" toggle switch**; toggling it hides OOC posts in-page and persists to the profile-level `hide_ooc` preference
- Users can hide OOC posts entirely via a profile-level preference (hide_ooc), surfaced as a toggle on the Profile page
- The composer ("Post a Reply") has a markdown textarea (≥16px to avoid iOS auto-zoom), a real OOC checkbox (18px box + label) and Attach control as comfortably-sized tap targets, and a gold "POST" button
- Post authors can edit their post within 10 minutes of creation; the edit window is enforced server-side
- Edit link is visible only while the edit window is open
- Posts support a draft state — a post can be saved as a draft before publishing
- Markdown formatting with a formatting toolbar and in-browser live preview (see "Markdown Editing" below)
- One image attachment per post
- One image attachment per scene

### Markdown Editing
- **Every user-editable multi-line text field is a markdown field** and shares the same editing affordances: a formatting toolbar directly above the textarea, with a live rendered preview below it. There is no such thing as a plain-textarea prose field — if a person can type multi-line prose into it, it renders markdown and carries the toolbar + preview.
- This applies to: the post composer, the standalone post-edit form, character sheets (new/edit), scene summaries, and the game description (New Game / Edit Game).
- The toolbar provides bold, italic, heading, quote, bulleted list, numbered list, link, and inline-code controls; each inserts the corresponding markdown around the current selection (or the current line, for block-level controls) and refreshes the live preview
- Single-line identifier inputs (e.g. game name, scene title) are **not** markdown fields — they are short labels, not prose, and get no toolbar.
- Not yet migrated to this rule (still plain textareas — outstanding work): the scene resolution/outcome field and the feedback modal body. New prose fields must ship as markdown from the start.

### File & Image Constraints
- Post and scene images: JPG, PNG, GIF, WEBP — 10 MB limit
- Game files: PDF, DOC, DOCX, TXT, MD, JPG, PNG, GIF, WEBP — 50 MB limit
- When a game file upload is rejected (too large, wrong type, etc.), the upload form redisplays with the validation error shown to the GM
- The game-file upload form warns client-side and disables submission when the selected file exceeds the size limit, before any upload is attempted

### Storage Namespacing & Metadata
- All new uploads are stored under a per-kind key prefix in the object store: `game_files/`, `exports/`, `scene_images/`, `post_images/`; derived assets (thumbnails, PDF previews) are stored under `variants/`. Existing objects keep their original keys.
- Each new primary upload carries R2 Custom Metadata (S3 `x-amz-meta-*`), set once at upload: `kind`, `game-id`, `user-id`, `uploaded-at`, `original-filename`, and `export-scope` (exports only). Metadata is for object legibility/debugging and does not drive automated behaviour.

### Export Retention
- Export archives are retained for 7 days. A daily background job deletes export requests older than 7 days and purges their archive from storage, matching the 7-day validity of the signed download link.

---

## Character Sheets

- A player can have multiple characters per game (main characters, retired characters, GM-created NPCs)
- When a player joins a game they do not yet have a character; they are prompted to create one but it is not required immediately
- Character creation requires a name; sheet content starts empty and can be filled in at any time
- Sheet content supports markdown, edited in a monospaced textarea with whitespace preserved (see "Markdown Editing" below)
- The character new/edit/show and version-history screens use the shared mobile-first component system (mobile frame + page header + design tokens), consistent with the rest of the app
- Characters can be marked inactive; inactive characters are hidden by default from the roster and dashboard
- The GM can create a character on behalf of any player
- The GM can edit any character sheet in their game
- Character sheets are visible to all game participants by default
- Players can mark their own sheet as hidden from other players
- The GM can hide all character sheets game-wide (overrides individual visibility)
- The GM can always see all sheets regardless of visibility settings

### Character Version History
- Every save of a character sheet automatically creates a version snapshot
- Version history shows: date, who made the change, and the full sheet content at that point
- Players and the GM can browse and view any historical version
- No diff view required for v1; full-text view per version is sufficient

---

## Game-Level File Store

- Shared file storage accessible to all active and removed game members (read)
- GM-only upload access
- GM can delete files
- Players can download files

### Gallery View
- Files are displayed as a visual gallery grid of thumbnail cards, not a plain table
- Image files (JPG, PNG, GIF, WEBP) display a thumbnail preview
- PDF files display a first-page preview image as their thumbnail
- Non-previewable files (DOC, DOCX, TXT, MD) display a styled placeholder card showing the file extension prominently
- When a thumbnail cannot be generated (missing dependency, corrupt file), the file-type placeholder is shown instead — no errors
- Clicking a card opens a modal lightbox with a larger preview
  - Images: displayed at larger size constrained to the viewport
  - PDFs: first-page preview at larger size (not a full PDF viewer)
  - Non-previewable files: placeholder at larger size plus filename and file size, with emphasis on the download button
  - Lightbox dismisses on backdrop click, Escape key, or close button
- Each card has a download button that does not trigger the lightbox
- GM cards include a delete button with confirmation; the delete button is visually distinct from the download button
- The upload form remains at the top of the gallery page, visible to the GM only
- File ordering is upload date descending (newest first)
- Thumbnails are generated lazily on first request; page load is not blocked by image processing

---

## Game Pages

Game-level wiki pages: freeform reference material (house rules, lore, NPC directories, session notes) that belongs to the whole game rather than any one scene or character.

- A page has a **title** and a markdown **body**. The body is optional; the title is required (max 200 characters).
- Each page is addressed by a **globally unique, non-editable 16-character alphanumeric slug** at `games/:game_id/pages/:slug`. The slug is generated automatically on creation and never changes — renaming a page's title never changes its URL. There is no user-facing slug field.
- **Only the GM can create, edit, or delete pages.** The new and edit screens use the same interface (shared `Shared::PageFormComponent`): a title field and the standard markdown editor (formatting toolbar + live preview, see "Markdown Editing"). Creating or saving lands on the page's show screen.
- **Every non-banned member of the game can view pages** — the GM, active players, and removed (former) players alike. Banned members and non-members are denied (redirected with an access alert). Enforced by `PagePolicy` (`show?` → game viewable; `create?`/`update?`/`destroy?` → GM).
- The page **show screen renders the markdown body** into the app's standard reading chrome (mobile frame + back-arrow header). The GM additionally sees Edit and Delete controls (delete is confirmed). A page with no body shows a placeholder.
- Pages are discovered through the **Pages tab** on the Game View, which lists every page in the game (alphabetised by title) and — for the GM — a "New Page" action.
- Pages are part of a game's lifecycle: they are **removed when the game is purged** (`GamePurgeJob`) and **included in the game export** (see Game Export).

---

## Notifications & Email

### Email Types
1. **Game invitation** — sent when GM invites a player
2. **New scene** — sent to all participants when a scene is created (except the creator)
3. **Post digest** — sent to participants who haven't visited a scene in 24+ hours, showing posts since their last visit (up to 10 posts, then "and N more..."); not sent if the participant authored all recent posts and there is nothing new from others
4. **Scene resolution** — sent to all participants when a scene is resolved, includes outcomes text
5. **Magic link login** — sent on sign-in request

### Reply-by-Email
- Notification emails include a reply-to address encoding the scene ID (`scene-{id}@{resend_inbound_domain}`)
- Replying to a notification email creates a post in that scene
- The sender must be a current scene participant; invalid senders are rejected
- Email content is cleaned before posting (quoted text, signatures, and formatting artifacts are stripped)
- Email-to-post always creates in-character posts; OOC posting requires the web interface
- If content cleaning fails after retries, the post is created from the raw email body and the sender is notified
- Inbound emails are delivered to the app via a Resend webhook (POST `/rails/action_mailbox/resend/inbound_emails`); the webhook is authenticated using HMAC-SHA256 signature verification (Svix standard) against the `resend_webhook_secret` credential
- Content cleaning uses OpenRouter (model `google/gemma-3-4b-it:free`); each successful API call writes an `AiUsage` record capturing `feature`, `model_used`, `input_tokens`, and `output_tokens`; a failed write is logged and does not interrupt email processing

### AI Usage Tracking
- Every successful AI API call writes an append-only `AiUsage` record: `feature` (string identifier, e.g. `"inbound_email"`), `model_used`, `input_tokens`, `output_tokens`, `created_at`
- Records are never updated after creation
- Fallback paths (no API key, network error, blank response content) do not write records
- Cost calculation and per-user/per-game aggregation are out of scope for this table; derive from queries as needed

### Notification Preferences
- Per-scene toggle: each participant can opt out of notifications for any scene they are in
- Absence of a preference record means notifications are enabled (opt-out model)
- Toggle accessible from the scene view and from active scene cards on the game view
- Removed and banned players no longer receive notifications

---

## Access Control Summary

| Action | Active member | Removed member | Banned member |
|--------|--------------|----------------|---------------|
| View game & scenes they participated in | Yes | Read-only | No |
| View game files | Yes | Yes | No |
| Post in scenes | Yes | No | No |
| Create scenes | Yes | No | No |
| View character sheets (respecting visibility) | Yes | Own only (read-only) | No |
| Receive notifications | Yes | No | No |
| Game appears on dashboard | Yes | Yes ("Former") | No |

### Authorization implementation (Pundit)

Every authorization decision is owned by a **policy object** — one per domain
model in `app/policies/`, each `ApplicationPolicy` subclass initialized with
`(user, record)` and therefore usable from any tier (controller, view, service,
mailbox) without a request. The rules in the table above are expressed there:

- **Action predicates** (`show?`, `create?`, `update?`, `resolve?`, `join?`,
  `manage_players?`, …) — the route/action gate. Controllers call `authorize
  @record`; an `after_action :verify_authorized` net fails any action that
  forgets to authorize (index/public/self-scoped actions are the only ones
  excepted per controller).
- **Scopes** (`ScenePolicy::Scope`, `CharacterPolicy::Scope`) — wrap the
  `visible_to` model scopes so a record outside a user's visibility is never
  loaded.
- **Field-level** (`permitted_attributes`) — e.g. only the GM assigns a
  character's owner (`user_id`); a player may still hide their own sheet.
- **Non-HTTP reuse** — `SceneMailbox` calls `ScenePolicy#reply_by_email?`
  directly (reply-by-email is allowed only for scene participants), and
  `PostPresenter#editable_by?` delegates to `PostPolicy#update?` so the post
  card and the controller share one decision.

Denials raise `Pundit::NotAuthorizedError` (→ a flash + `redirect_back`); loading
a record through a policy scope that excludes it yields a 404 (existence is not
leaked). Controllers preserve their specific denial copy where it is
user-facing (no-access, hidden-sheet, cannot-edit, GM-only). Profiles are
governed by an owner rule (`record.user == user`), not skipped. The only
authorization-exempt controllers are those with no authenticated user: Devise
sessions, the deploy webhook, the inbound-email ingress, and public invitation
acceptance.

---

## Game Export

- Any non-banned game member (active, GM, or removed) can request a zip export of a game
- Removed members export only scenes they participated in; active members and GMs see all scenes visible to them
- Banned members cannot export
- "Export All Games" on the profile page bundles all non-banned games into a single zip archive
- Exports are assembled in the background via `ExportJob` (Solid Queue)
- Delivery: a 7-day signed Active Storage download link sent via `ExportMailer#export_ready`
- Requests are unlimited and the export button is always enabled; processing is throttled to at most one successful export per user per game per 24-hour rolling window (all-games is tracked independently as `game: nil`)
- The **receipt** — a `GameExportRequest` with `succeeded_at` set within the 24-hour window and its archive still attached — is the source of truth for the flow:
  - If a valid receipt exists, a new request **resends** that export's existing download link (`ExportDelivery.email_download_link`) instead of reprocessing
  - If not, a new export is processed; on success `succeeded_at` is stamped (the receipt is written). A failed export leaves `succeeded_at` nil, so it never blocks or throttles a retry
  - Receipt expiry (24 hours) governs: after the window a new request reprocesses a fresh export even if the old 7-day link is still valid
- The game and profile pages show a passive "Last export: X ago" notice (from the receipt's `succeeded_at`) beside the always-enabled button; nothing is shown when no valid receipt exists
- Clicking the export button submits immediately — no confirmation dialog — and the acknowledgment ("Export requested — you'll receive an email shortly.") renders on screen via the standard flash notice; delivery-window and link-expiry details are shown as static helper text next to the button instead
- `succeeded_at` is indexed `(game_id, succeeded_at desc)` so the receipt lookup is a fast indexed read
- If a job fails, `ExportMailer#export_failed` is sent and the job re-raises (for retry by Solid Queue)
- Archive structure: `{game-slug}-export-{date}/README.md`, `files_manifest.md`, `scenes/NNN-{slug}/scene_info.md`, `scenes/NNN-{slug}/posts.md`, `characters/{slug}/current_sheet.md`, `characters/{slug}/version_history/vNNN-{date}.md`, `pages/{slug}.md`
- Game pages are exported as `pages/{slug}.md` (slug derived from the page title, disambiguated on collision), each with the title as an H1 and the markdown body
- Drafts are excluded from posts; binary game files are excluded (a manifest is included)
- User emails are never written to the archive; only display names
- Zip files are purged from Active Storage after 7 days

---

## CSS Component Coverage

- CSS styling is progressively migrated from plain ERB view templates to ViewComponent files
- `bin/quality-metrics` tracks a `css_in_components_pct` metric: the percentage of CSS statements in ViewComponent templates (`app/components/**/*.html.erb`) versus all application view templates (`app/views/**/*.html.erb`, including mailer views — mailers can render components just as web views can); a CSS statement is either a whitespace-separated token in a `class="..."` attribute or a semicolon-separated declaration in a `style="..."` attribute
- The metric uses a floor model — it can only improve; any decrease below the recorded baseline fails the quality gate
- Run `bin/quality-metrics --save` after intentional migration work to advance the baseline
- Target is 100% (all styling in components; no inline CSS in plain ERB views)

---

## ERB Logic in Presenters

- ERB templates (both `app/views/**/*.html.erb` and `app/components/**/*.html.erb`) must stay thin; display logic belongs in presenter or component Ruby classes
- `bin/quality-metrics --check` detects three indicator patterns that signal logic has leaked into a template:
  - **Ternary in output tag** — `<%= expr ? val : val %>`: conditional value selection should be a presenter method; a space before `?` distinguishes the ternary operator from predicate method calls ending in `?`
  - **Boolean OR fallback in output tag** — `<%= a || b %>`: fallback/default logic (e.g. `display_name || email`) should be a presenter method
  - **Local variable assignment** — `<% var = value %>`: data preparation or intermediate calculations in the template should move to the component class or controller; control-flow bindings (`if`, `each do |x|`, etc.) are excluded
- The check uses a delta model: changed ERB files must not gain logic indicators compared to `origin/master`; existing indicators are grandfathered and do not block the build
- To reduce existing indicators, move the logic to the appropriate presenter or component method and verify the count decreases

---

## Presenter Method Coverage

- Public instance methods explicitly declared in model files should live in presenters when their only callers are ERB view templates or mailer Ruby files
- `bin/quality-metrics` tracks a `presenter_method_violations` count: the number of such methods found by static analysis (word-boundary search across `app/views/**/*.erb`, `app/components/**/*.erb`, and `app/mailers/**/*.rb` for call sites, with `app/models/**/*.rb` excluded as the defining files)
- A method is a *violation* when it has at least one call site in the presentation layer and zero call sites anywhere else in the application (controllers, presenters, components Ruby classes, jobs, services, helpers, etc.)
- The metric uses a ceiling model — the violation count can only decrease; any increase above the recorded baseline fails the quality gate
- Run `bin/quality-metrics --save` after moving a method to a presenter to lower the baseline
- In `--check` mode, each violation is listed with its call sites to aid remediation
- Methods shorter than four characters are excluded to reduce false-positive matches on common short names
- Presenters that gain new methods via this migration must be added to `.mutant.yml` under `matcher.subjects` so mutation coverage is tracked

---

## Baseline Integrity Gate

- `quality_baseline.json` records the static thresholds that all quality checks are measured against
- When `bin/quality-metrics --check` runs and `quality_baseline.json` has changed relative to `origin/master`, the gate verifies that every metric in the baseline only moved in the direction of improvement before running any other checks
- "Improvement" follows each metric's model: floor metrics (`line_coverage`, `branch_coverage`, `sorbet_typed_pct`, `mutation_coverage`, `css_in_components_pct`) may only increase; ceiling metrics (`presenter_method_violations`) may only decrease
- If any metric in the baseline file regressed, the gate fails immediately with a clear message listing each offending metric — no further checks run
- This prevents gaming the quality pipeline by lowering baseline thresholds to make a PR pass

---

## AI Scene Summaries

- GMs can write scene summaries manually at any time after a scene is resolved
- If `ai_summaries_enabled` is toggled on for the game, a background job (`SceneSummaryJob`) automatically generates a summary via OpenRouter when a scene is resolved
- The AI summary is upserted — re-resolving or re-enqueueing never creates duplicates
- GMs can edit or delete any summary (AI-generated or hand-written)
- Editing an AI-generated summary clears `generated_at`, `model_used`, and token counts, marking it as hand-edited
- Private scenes are never included in the campaign log or RSS feed
- Only resolved, non-private scenes appear in the campaign log
- The campaign log is paginated (HTML) or limited to 20 most recent entries (RSS), ordered by `resolved_at` descending
- The RSS feed is accessible with a per-user secret token (query param `?token=…`) or by an active game member via session
- RSS tokens are per-user, valid across all games; users generate/rotate/revoke from their profile
- AI provider: OpenRouter (OpenAI-compatible); configured via `OPENROUTER_API_KEY` and `OPENROUTER_MODEL` env vars
- The service raises `SceneSummaryService::ConfigurationError` if `OPENROUTER_API_KEY` is absent
- OOC posts are sent to the model labelled `[OOC]`; the model decides narrative relevance
- Token counts (`input_tokens`, `output_tokens`) and `model_used` are stored on `SceneSummary`; `generated_at` non-null indicates AI-produced content

### Summary status labels
- `generated_at` present, `edited_at` nil → "AI-generated"
- `generated_at` present, `edited_at` present → "Edited"
- `generated_at` nil → "Hand-written"

---

## RSS Token Management

- Each user has at most one RSS token, accessible from their profile page
- Tokens are 64-character random hex strings
- Users can generate a new token (or rotate an existing one) from their profile
- Revoking a token immediately invalidates all feed URLs that use it
- Token access is checked at request time against current active (non-banned) game membership

---

## Error Tracking

- Unhandled exceptions are reported via the Sentry SDK (`sentry-ruby`, `sentry-rails`) to a self-hosted GlitchTip instance, which speaks the Sentry protocol
- Reporting is DSN-gated: `Sentry.init` only runs when `glitchtip.dsn` (credentials) or `GLITCHTIP_DSN` (env var fallback) is present, so local development and CI run without a configured DSN and without reporting errors anywhere
- No PII scrubbing beyond the SDK's defaults is configured; do not log request bodies or user-supplied content into breadcrumbs

## Deployment

- After the GitHub Actions build workflow pushes a new production image (on `master`), it POSTs to the app's deploy relay endpoint (`POST /webhooks/deploy`) with a shared bearer secret
- The relay exists because Coolify (the deployment orchestrator) is not exposed to the internet; the app is internet-facing and can reach Coolify over the internal network, so it forwards the deploy trigger on GitHub's behalf
- The relay is authenticated by a constant-time comparison against the `deploy_webhook_secret` credential; a missing or mismatched secret is rejected with 401 and no relay occurs
- On a valid request the relay enqueues a background job that issues an authorized GET to Coolify's per-app deploy URL (`coolify.deploy_url` / `coolify.token` credentials); the HTTP response to GitHub is immediate (`202 Accepted`) and the forward is retried on failure

---

## Design Assumptions

- All players are adults who are not cheating; no roll resolution system is needed
- Scene resolution is the GM's call — players do not approve or vote
- Multiple scenes can run simultaneously within a game
- Scenes and games are associated with players (via membership), not with individual characters
- No explicit linking of scene outcomes to character sheets is required

---

## View Architecture Conventions

- Dead ERB partials that have been superseded by ViewComponents are deleted; do not leave both in place
- Presenters are always instantiated in controllers, not in views; controllers wrap models in presenter instances and assign them as instance variables; views consume presenters directly and never instantiate them — this maintains a clear, consistent interface between the controller and view layers
