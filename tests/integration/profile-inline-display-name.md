# Testing plan — edit Display Name inline on the Profile page (Fizzy #124)

The Display Name row on `/profile` no longer navigates to a separate edit page.
Clicking "Edit" swaps the row into a text field with Save/Cancel, in place; Save
persists and swaps back to the display row with a toast. The old `edit_profile`
page/route/controller actions and `Shared::ProfileFormComponent` are removed —
display name was the only field they hosted.

Verify on **both viewports** (below and above the 1024px breakpoint).

## Profile show page (`/profile`)

- [ ] **View mode by default.** The Display Name row shows the current name (or
      "Not set") and an "Edit" control; no input field is visible.
- [ ] **Edit reveals the field.** Clicking "Edit" swaps the row to a text input
      pre-filled with the current name, focused, with Save and Cancel controls.
      No navigation occurs (URL stays `/profile`).
- [ ] **Save persists in place.** Typing a new name and clicking Save updates the
      row back to view mode showing the new name, with a confirmation toast — no
      full page reload (a marker set on `body`/`main` before Save survives).
- [ ] **Cancel discards.** Opening edit mode, changing the text, then clicking
      Cancel reverts to view mode showing the original (unsaved) name, with no
      request sent.
- [ ] **Validation failure stays in edit mode.** Submitting a name that fails
      validation (e.g. blank) keeps the row in edit mode with the error message
      shown, via a Turbo Stream re-render (not a redirect).
- [ ] **Nav drawer reflects the new name** after a successful save (same source
      as before, just via the in-place path now).
- [ ] **No edit page remains.** `/profile/edit` no longer exists (404 / route
      removed); nothing else links to it.

## Both viewports

- [ ] Repeat "Edit reveals the field" and "Save persists in place" at 375×812
      (mobile) and 1280×900 (desktop) — the swap and toast behave the same at
      both sizes.
