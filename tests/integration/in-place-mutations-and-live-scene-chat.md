# Testing plan — in-place mutations app-wide + live scene chat (Fizzy #123)

Two related changes, one root cause (redirect-after-mutation → full-page reload):
mutations that stay on the current screen now update in place with a toast, and
scene posts appear/update live for every viewer.

Verify on **both viewports** (below and above the 1024px breakpoint) where a
screen differs. A "toast, no scroll jump, no full reload" outcome is the pass
condition for every in-place item.

## Live scene chat (Part B)

Two browsers, two members (GM + player) of the same game, both on the same scene.

- [ ] **Player posts → GM sees it live.** Player writes a post and clicks POST.
      It appears in the GM's post list within a second or two **without the GM
      reloading**. The player sees their own post immediately (composer resets).
- [ ] **No duplicate for the author.** The player's own post appears exactly once
      (not twice) — the submitter's immediate append and the broadcast collapse on
      the shared `dom_id`.
- [ ] **Author keeps Edit.** The player still sees an **Edit** link on their own
      just-posted message (within the edit window); the GM does **not** see an Edit
      link on the player's post.
- [ ] **Live edit.** Player edits their post (Edit → change → Save). The GM's copy
      updates in place; the "(edited)" marker appears for both.
- [ ] **OOC hiding on a streamed post.** GM turns on "Hide OOC" (scene control),
      then the player posts an OOC message. The OOC post is hidden for the GM
      (revealed when the GM toggles OOC back on) — the live node is filtered too,
      not just posts present at page load.
- [ ] **Non-participant / private scene.** A game member who is not a participant
      of a *private* scene cannot subscribe (no live posts leak); a participant
      does receive them.

## In-place mutations (Part A)

### Profile (`/profile`)
- [ ] AI display preference — segmented control updates in place + toast.
- [ ] Hide-OOC toggle — flips in place.
- [ ] BYOK key set-up / save / delete — in place (unchanged reference behavior).
- [ ] **Fund AI for your games** toggle — flips in place, funding rows update.
- [ ] **API / feed token** create and revoke — token row updates in place.
- [ ] **Export all games** — toast only, no reload.
- [ ] **Avatar** upload (cropper), make-current, delete — library updates in place,
      cropper modal closes, no reload.

### Character (`/games/:g/characters/:c`)
- [ ] **Edit sheet → Save** — stays on the form with a toast (Turbo); a validation
      error shows in place. (A non-Turbo client still redirects to the sheet.)
- [ ] Portrait upload / make-current / delete — library updates in place.
- [ ] Archive / restore — still navigate to the sheet (state transition): expected.

### Game settings & roster
- [ ] **Sheet visibility** toggle (edit game) — flips in place, stays on the edit
      page, label swaps.
- [ ] **AI Scene Summaries** toggle — flips in place.
- [ ] **Remove / Ban / Reinstate** a member (Player Management) — the Members roster
      re-renders in place with the new controls; the list can go empty in place.
- [ ] **Invite / Cancel / Resend** (Roster tab) — the invite panel + pending list
      update in place.

### Lists
- [ ] **Game link** delete — list updates in place (empty-state appears when last
      one goes). Create/edit still navigate (separate form pages): expected.
- [ ] **Content template** delete — list updates in place.
- [ ] **Game file** upload and delete — files list updates in place, no reload.

### Scene
- [ ] **Mute / Unmute notifications** — the mute button label swaps in place + toast.
- [ ] Resolve, Join — still navigate (major state change re-renders the scene):
      expected.

## Regression / gate
- [ ] `bundle exec rspec` green, then `bin/quality-metrics --check`.
- [ ] `bundle exec srb tc` clean; `bin/pre-push` passes; `bin/full-check` (system +
      mutation + quality) green.
- [ ] Authorization denials on every converted action still redirect (not an
      in-place 200).

---

# Known gaps / remaining in-place work (audit-verified)

Scope reminder: **every user-facing operation that does not require a true page
refresh should be Hotwire/Stimulus-driven** (smooth, no full reload). This section
inventories what is DONE, what is NOT DONE, and what legitimately stays a full
navigation. Verified by two skeptical audits + a full-nav source sweep
(redirect_to, full-page renders, `turbo: false`, and JS `location.reload`).

## RESOLVED (second pass) — gaps 1–4, 6, 10 closed

Gaps 1, 2, 3, 4 (functional) and 6, 10 (consistency/test) below were fixed:
- #1 reply-by-email now broadcasts (`SceneMailbox#process` → `PostBroadcast`).
- #2 live posts glow: broadcast renders created posts `force_unread`; `unread_aura`
  controller gained a MutationObserver + un-glows the author's own post.
- #3 lightbox delete applies the Turbo Stream (`Turbo.renderStreamMessage`) instead
  of `window.location.reload()`.
- #4 `SceneSummary#update` adopts `InPlaceSave` + `update.turbo_stream.erb`.
- #6 `GameExports#create` is now toast-in-place, matching `profiles#export_all`.
- #10 stale image-spec descriptions renamed.
Still open: #5 (turbo_or_redirect used only by posts), #7 (image-library id in view
wrapper), #8 (no two-real-session system spec — partially mitigated with glow +
author-suppression browser tests), #9 (toast target unasserted in some specs).

## NOT DONE (original list — see RESOLVED above for what is now closed)

1. **Reply-by-email posts do not broadcast** — `app/mailboxes/scene_mailbox.rb:16`
   creates the post via `posts.create!` and never calls `PostBroadcast`. A post made
   by replying to a notification email does NOT appear live for viewers on the scene;
   they must reload. Fix: `PostBroadcast.new(post).created` after the create. Add a
   mailbox spec asserting the broadcast fires. (Contradicts "posts appear live for
   everyone.")

2. **Unread glow never appears on a live-streamed post** — `PostBroadcast#component`
   (`app/models/post_broadcast.rb:53`) passes no `read_post_ids`, so a streamed post
   renders `data-unread="false"`; and `app/javascript/controllers/unread_aura_controller.js`
   only scans `[data-unread="true"]` once in `connect()` (no MutationObserver). Net:
   the newest posts — the live ones — never glow and never auto-mark-read. The
   `PostBroadcast` comment claiming the client "reconciles reads on its own" is false
   and must be corrected. Fix options: broadcast a per-viewer-neutral "unread" render
   + add a MutationObserver to unread-aura that glows/marks-read new nodes for
   non-authors; author's own post stays un-glowed.

3. **Game-file delete from the lightbox still full-reloads** —
   `app/javascript/controllers/lightbox_controller.js:60` does
   `fetch(DELETE).then(() => window.location.reload())`. It hits the SAME
   `GameFilesController#destroy` that now returns a Turbo Stream, but ignores the
   stream and reloads. Fix: apply the response via `Turbo.renderStreamMessage` and
   close the lightbox (mirror the image-cropper fix), so lightbox delete matches the
   in-place list delete.

4. **Missed in-place conversion: `SceneSummariesController#update`** —
   `app/controllers/scene_summaries_controller.rb:45` still `redirect_to`s. It is a
   long-form markdown editor (`SceneSummaryFormComponent` → `Ui::MarkdownEditorComponent`,
   with preview) — structurally identical to Pages, Notebook, and Character sheet,
   all three of which use `InPlaceSave`. Character was converted on this branch and
   called "the flagship inconsistency"; scene summary is the same shape and was left
   out. Fix: adopt `InPlaceSave` + add `scene_summaries/update.turbo_stream.erb`
   (mirror `characters/update.turbo_stream.erb`).

## PARTIALLY DONE — consistency / robustness follow-ups

5. **`turbo_or_redirect` html-fallback used only by PostsController.** The helper in
   `InPlaceRender` gives a non-Turbo request a sensible redirect, but every other
   converted action bare-renders `turbo_stream:` with no html branch. In practice the
   forms are Turbo `button_to`/form submissions (Accept carries turbo-stream), so it
   works — but the plumbing is inconsistent. Either route all in-place actions through
   `turbo_or_redirect`, or delete the helper's fallback ambition and document that
   in-place actions are Turbo-only by contract.

6. **`GameExportsController#create` redirects while `profiles#export_all` is in-place.**
   Same "fire-and-forget export, email sent" operation, opposite treatment. Decide one
   way (toast-in-place is the smoother choice) and align them.

7. **Image-library swap targets live in view wrappers, not the component.**
   `image_library_user_image` / `image_library_character_image` ids are `<div>`s in
   `profiles/show.html.erb` / `characters/show.html.erb`, not on the
   `ImageLibraryComponent` root. Deleting a wrapper silently no-ops the swap, and the
   specs (which assert the id appears in the response body, not that it is the stream
   *target*) would not catch it. Consider giving the component root the id.

## TEST GAPS (behavior works, coverage is thin)

8. **No true two-viewer system spec for live chat.** `spec/system/live_scene_posts_spec.rb`
   is a single-session stand-in that broadcasts server-side within one browser (it says
   so in a comment) — it never proves a second real viewer sees a post submitted
   through the actual controller, nor exercises the author's-own-tab dedup in a browser.

9. **Toast target unasserted in 7+ converted request specs** (mute, game files, links,
   templates, members, invitations, images). The toast is half the in-place contract
   `[stream, toast_stream]`; a dropped `toast_stream` would not be caught. Add a
   `response.body` includes `"toast_layer"` assertion to each.

10. **Stale spec descriptions.** Three image specs
    (`character_images_spec.rb:66`, `image_library_spec.rb:65,73`, `user_images_spec.rb:50`)
    still say "redirects with an alert" but now assert `have_http_status(:ok)`. Rename.

## LEGITIMATELY full navigation (correct — leave as redirect)

- Create-a-new-resource you land on: games / scenes / pages / characters / content
  templates / game links / game files (create), notebook `promote`.
- Delete-what-you-are-viewing: game destroy, page destroy (page detail), notebook
  destroy (edit page), scene summary destroy.
- Major state transition re-rendering most of the scene: scene resolve, scene
  participant join, character archive/restore.
- Cross-session sign-in landing: invitation `accept`.
- Pre-auth / mounted-engine / file-download `turbo: false`: sign-in form, `/api-docs`
  link, gallery download link.
- Standalone edit-form navigations (GET to a full form page): edit game, edit
  participants, new/edit link/template. (These are page-to-page navigations, not
  in-place mutations; converting them to Turbo-Frame in-place editing is a larger
  UX change, out of the redirect-after-mutation scope.)
