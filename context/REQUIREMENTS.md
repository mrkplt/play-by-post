# Play-by-Post TTRPG — Product Requirements

Asynchronous tabletop RPG platform. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

For technology stack, domain model, codebase conventions, and development workflow see [CLAUDE.md](../.claude/CLAUDE.md).

---

## Authentication & Accounts

- Authentication is magic link only — no passwords
- New users arrive via invitation magic links; there is no standalone signup page
- A magic link from an invitation creates a new account or links to an existing one
- After first login, users must set a display name before using the app
- Display names are required and shown throughout the app for authorship attribution

---

## Player Dashboard

- Landing page after login shows all games the player belongs to
- Each game card shows: game name, player's primary character name (linked to sheet), number of active scenes, and a "new activity" indicator if anything changed since last login
- Players with multiple characters see their primary character name with a "+N" count for additional characters
- Clicking a game navigates to the game view
- Removed players see their game with a "Former" indicator
- Banned players do not see the game at all

---

## Game Creation

- Any logged-in user can create a new game
- Game creation requires a name; description is optional
- Game creator automatically becomes the Game Master (GM)
- Game creation requires a confirmation step before submission
- After creation, the GM lands on the game view

---

## Player Profile

- Each user has a profile page showing their display name and list of games with their role
- Profile is accessible from the navbar
- Users can edit their display name from the profile page

---

## Game View

- Shows the game name and description
- Character roster listing all characters and their owning players, visible to all participants
- Inactive characters hidden by default from the roster; accessible via a filter or toggle
- Active (unresolved) scenes listed prominently, most recent first
- Resolved scenes in a separate paginated list (10 per page, chronological descending)
- Game files section shows a compact file list with a link to the full gallery; non-GM members have a "View Files" link (not just GM)
- GM sees player management controls (invite, remove, ban)

---

## Player Management

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
- The game remains on the removed player's dashboard with a "Former" indicator
- The character roster shows a "Removed" status for the player

### Player Banning (adversarial, GM's discretion)
- GM can ban a player — distinct from removal, with a separate confirmation that communicates permanent access revocation
- Banned players lose all access: game, scenes, posts, characters, files, everything
- The game disappears from the banned player's dashboard entirely
- Banned players no longer receive notifications
- The character roster shows a "Banned" status visible only to the GM

---

## Scenes

### Scene List Behaviour
- Scenes ordered most recent first (descending timestamp)
- Scenes sharing the same parent scene are grouped on the same row (parallel branches)
- Private scenes visible only to participants and the GM
- Resolved scenes displayed separately from active scenes

### Quick Scene (from scene view)
- Creates a new scene inheriting all participants and parent from the current scene
- Minimal form: title and description only
- Private flag inherited from the parent scene
- Intended for continuing the narrative with the same group

### New Scene (from scene view or game view)
- Full form: title, description, participant selection, parent scene, private flag, optional image
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

- Posts are flat within a scene (linear thread, not nested replies)
- Each post shows: author display name, timestamp, markdown-rendered body, optional image
- Posts can be marked Out-of-Character (OOC); OOC posts are visually distinct
- OOC posts can be filtered out of the scene view
- Users can hide OOC posts entirely via a profile-level preference (hide_ooc)
- Post authors can edit their post within 10 minutes of creation; the edit window is enforced server-side
- Edit link is visible only while the edit window is open
- Posts support a draft state — a post can be saved as a draft before publishing
- Markdown formatting with in-browser live preview
- One image attachment per post
- One image attachment per scene

### File & Image Constraints
- Post and scene images: JPG, PNG, GIF, WEBP — 10 MB limit
- Game files: PDF, DOC, DOCX, TXT, MD, JPG, PNG, GIF, WEBP — 25 MB limit

---

## Character Sheets

- A player can have multiple characters per game (main characters, retired characters, GM-created NPCs)
- When a player joins a game they do not yet have a character; they are prompted to create one but it is not required immediately
- Character creation requires a name; sheet content starts empty and can be filled in at any time
- Sheet content is plain text, rendered monospaced with whitespace preserved
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

---

## Game Export

- Any non-banned game member (active, GM, or removed) can request a zip export of a game
- Removed members export only scenes they participated in; active members and GMs see all scenes visible to them
- Banned members cannot export
- "Export All Games" on the profile page bundles all non-banned games into a single zip archive
- Exports are assembled in the background via `ExportJob` (Solid Queue)
- Delivery: a 7-day signed Active Storage download link sent via `ExportMailer#export_ready`
- Rate limit: one export request per user per game per 24-hour rolling window; all-games has its own independent 24-hour limit
- Rate limits are tracked in the `game_export_requests` table
- If a job fails, `ExportMailer#export_failed` is sent and the job re-raises (for retry by Solid Queue)
- Archive structure: `{game-slug}-export-{date}/README.md`, `files_manifest.md`, `scenes/NNN-{slug}/scene_info.md`, `scenes/NNN-{slug}/posts.md`, `characters/{slug}/current_sheet.md`, `characters/{slug}/version_history/vNNN-{date}.md`
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

## Design Assumptions

- All players are adults who are not cheating; no roll resolution system is needed
- Scene resolution is the GM's call — players do not approve or vote
- Multiple scenes can run simultaneously within a game
- Scenes and games are associated with players (via membership), not with individual characters
- No explicit linking of scene outcomes to character sheets is required

---

## View Architecture Conventions

- Dead ERB partials that have been superseded by ViewComponents are deleted; do not leave both in place
- The Gallery component (`Shared::GalleryComponent`) delegates all URL construction and HTML generation for thumbnails and lightbox content to typed methods on the component class; the ERB template only iterates and renders
- The post list in `scenes/show` is built from `@post_presenters` (an `Array[PostPresenter]` constructed in `ScenesController#show`); the view does not instantiate presenters itself
- Player names in all views use `UserPresenter#display_name_or_email`, which falls back to the email prefix (text before `@`) when no display name is set; this replaces the inline `display_name || email` pattern and applies to all views including the player management table (previously used `"—"` as the fallback)
- The parent scene select in the new scene form uses `ScenePresenter#parent_option_label` to format options; resolved scenes are shown as "Title (Resolved)"
