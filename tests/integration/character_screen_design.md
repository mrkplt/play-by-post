# Character Screen — Design System + Markdown Formatting Controls

Covers the redesign of the character new/edit/show/version screens onto the
mobile-first component system, and the markdown formatting toolbar added to the
sheet editor.

## New / Edit character form

1. As a player, open a game → Roster tab → **New Character**.
   - The screen uses the dark page header (back arrow → game) with the title
     "New Character", inside the standard mobile frame — not a bare `<h1>`.
   - Fields: **Name**, and a **Sheet** editor with a formatting toolbar above
     the textarea and a live preview panel below it.
   - Buttons are the gold **Create Character** primary and a bordered
     **Cancel** — no slate-grey buttons anywhere.
2. As a GM, open **New Character**.
   - A **Player** selector appears above the name field.
3. Formatting toolbar (per button):
   - Select some text, click **B** → wraps it in `**…**`; preview shows bold.
   - Select text, click **I** → wraps in `_…_`.
   - Click **H** on a line → prepends `## `.
   - Click **“** (quote) → prepends `> `; **• List** → `- `; **1. List** → `1. `.
   - Click **Link** with text selected → `[text](url)` with `url` selected.
   - Click **Code** → wraps in backticks.
   - With nothing selected, each inline button inserts a placeholder and selects it.
   - After any button, the live preview updates immediately.
4. Edit an existing character:
   - Header title is "Edit — {name}".
   - A **Hide from other players** checkbox is present.
   - GM only: an **Archive character** (or **Restore character** when archived)
     action below the form.

## Show / version screens

5. View a character sheet: mobile frame + page header (back → game), the sheet
   rendered in a bordered card, Archived/Hidden badges, an **Edit** link (when
   permitted), and the **Version History** disclosure with a date/editor table.
6. Open a historical version: page header (back → character), a meta line
   (version timestamp + editor), and the version content in a bordered card.

## Responsive

7. At mobile (375px) and desktop (1280px): no horizontal scroll, textarea and
   preview stay within the frame, toolbar buttons wrap rather than overflow.

## Regression

8. Existing character request/system specs still pass (labels "Sheet …",
   "Create Character", "Save", "Hide from other players", version-history
   `<details>`/`<summary>` and table are preserved).
