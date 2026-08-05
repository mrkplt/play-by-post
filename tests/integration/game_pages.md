# Game Pages — GM-authored wiki pages

Covers game-level pages: GM creates/edits/deletes markdown pages that belong to
the whole game; every non-banned member can read them at
`games/:game_id/pages/:slug`.

## Pages tab (Game View)

1. Open a game. The dark header now shows **four** pill tabs: Scenes / Roster /
   Files / **Pages**. Tapping **Pages** switches in-page (no navigation); the
   URL hash becomes `#pages` and is deep-linkable.
2. As the GM, the Pages tab shows a gold **New Page** action above the list.
   - As an active player or a removed (former) player, the list is visible but
     **New Page is absent**.
3. Each page appears as a row (title) linking to its show screen; rows are
   ordered alphabetically by title. With no pages, an empty-state note shows.

## New / Edit page

4. As the GM, Pages tab → **New Page**.
   - Dark page header (back arrow → game `#pages`) titled "New Page" inside the
     standard mobile frame.
   - Fields: **Title**, and a **Body (markdown supported)** editor with the
     formatting toolbar above the textarea and a live preview panel below it —
     the same markdown affordances as the post composer and character sheet.
   - No slug field is shown; the slug is generated server-side.
   - Buttons: gold **Create Page** primary and a bordered **Cancel**.
5. Submit with a blank title → the form redisplays with a validation error.
6. Submit a valid title/body → lands on the page's show screen; the URL is
   `games/:id/pages/:slug` where slug is a 16-character alphanumeric string.
7. Edit an existing page (GM only): header title "Edit — {title}", same form.
   - Changing the **title** and saving does **not** change the slug/URL.

## Show screen

8. View a page: mobile frame + page header (back → game `#pages`), the markdown
   body rendered in a bordered card. A body-less page shows a placeholder.
9. GM only: **Edit** and **Delete** controls appear above the card; Delete asks
   for confirmation and returns to the game Pages tab.

## Access control

10. A page URL opened by a **banned** member or a **non-member** redirects with
    an access alert; an unauthenticated visitor is redirected to sign in.
11. A non-GM member who POSTs/PATCHes/DELETEs a page directly is rejected (only
    the GM can mutate pages).

## Lifecycle

12. Deleting the game (soft delete → purge) removes its pages along with
    everything else (`GamePurgeJob`).
13. A game export archive contains a `pages/{slug}.md` file per page (slug from
    the title, disambiguated on collision), each with the title as an H1 and
    the markdown body.
