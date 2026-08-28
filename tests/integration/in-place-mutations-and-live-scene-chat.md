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
