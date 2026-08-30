# Integration test plan — image library click-to-preview + Save (Fizzy #127)

`Shared::ImageLibraryComponent` (avatar on `/profile`, character portraits on
`/games/:game_id/characters/:character_id`) shows the current image large, a grid of
thumbnails, and per-thumbnail controls. Today clicking "Use" round-trips to the server
immediately; the large image only updates after that swap. The card wants selection to be
instant (client-side) and persistence explicit (a Save button), with a toast confirming the
save. Both call sites share the same component/controllers (`ImageLibrary` module), so both
convert together — no owner-specific behavior split.

## Mechanism (decided)

- **Client-side preview, server-side persistence.** A new Stimulus controller
  (`image-select`) owns: clicking a thumbnail updates the large `<img src>` immediately and
  moves the selection ring, tracks a "pending" image id, and enables the Save button only
  when the pending id differs from the image already marked current server-side (dirty
  check). Save does a `fetch` PATCH to that image's existing `set_current_url` (the same
  endpoint the old "Use" button hit) with `Accept: text/vnd.turbo-stream.html`, then applies
  the response via `Turbo.renderStreamMessage` — same shape as `image_cropper_controller.js`.
  No `window.location.reload()`.
- **The "Use" button_to is deleted**, not hidden behind a flag — selection is by clicking the
  thumbnail image itself now.
- **The endpoint contract is unchanged.** `ImageLibrary#update` (shared by
  `UserImagesController` / `CharacterImagesController`) already responds with a Turbo Stream
  that replaces `#image_library_<kind>` and a toast — exactly the response shape the new
  fetch needs. No controller/route change; only the client trigger changes (JS fetch instead
  of a form submit) and the request specs assert the same PATCH still works when invoked via
  a Turbo Stream `Accept` header.
- **Delete is unchanged** (still a `button_to` per thumbnail, unaffected by selection state).

## Scenarios

### A. Component (both owner shapes: avatar item set, portrait item set)
1. Empty library → empty text, no thumbnails, no Save button.
2. Populated, viewer can manage → large current image, N thumbnails, each thumbnail
   clickable (no "Use" link present anywhere), Delete present per thumbnail, one Save button
   present (disabled/inert until a new selection is made).
3. Populated, viewer cannot manage → no Delete, no Save, thumbnails not selectable.

### B. Request specs (both `UserImagesController` and `CharacterImagesController`)
- PATCH to an image's set-current URL with `Accept: text/vnd.turbo-stream.html` still marks
  it current, unmarks the prior current, and responds 200 with a Turbo Stream body that
  includes the library target id and a toast partial — same assertions the existing specs
  already make, now also covering the turbo-stream Accept header explicitly.

### C. System (both viewports, 1024px breakpoint)
1. Visit profile (avatar) / character (portrait) with 2+ images, one current.
2. Click a non-current thumbnail → the large image at top updates to that thumbnail's image
   **immediately**, with no page reload and no network wait (assert before any server
   response could land, or assert no visible "Image updated" toast yet).
3. Click Save → toast "Image updated." appears, the clicked image is now `current?` in the
   DB, thumbnail ring moves to the new current image.
4. Clicking the already-current thumbnail leaves Save disabled/inert (no-op, nothing to
   persist).

## Automated coverage
- `spec/components/shared/image_library_component_spec.rb` — updated: drop Use assertions,
  add Save-button and thumbnail-click-target assertions.
- `spec/requests/user_images_spec.rb`, `spec/requests/character_images_spec.rb` — PATCH
  still persists + returns the in-place Turbo Stream + toast.
- `spec/system/user_avatars_spec.rb`, `spec/system/character_portraits_spec.rb` — replace the
  "Use" system-spec scenario with click-preview → Save → toast, both viewports.
