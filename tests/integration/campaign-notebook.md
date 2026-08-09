# Campaign Notebook — GM-only kanban scratchpad

Covers the Notebook tab: a GM-only kanban board of short entries (New / Expand
/ Done / Discard lanes) that live above formal Pages, with an explicit
"Promote" action that turns an entry into a full game Page.

## Notebook tab visibility

1. As the GM, open a game. The dark header now shows a **Notebook** pill tab
   alongside Scenes / Roster / Files / Pages / Links.
2. As an active player or a removed (former) player, the **Notebook tab is not
   present** in the header at all.
3. A player who navigates directly to `games/:id/notebook_entries` is
   redirected away with an alert; they never reach the board.

## Create / edit / delete an entry

4. As the GM, open the Notebook tab. Each lane (New / Expand / Done) is a
   column; a **Discard** column exists but is hidden by default behind a
   "Show discarded" toggle.
5. Create a new entry (title + markdown body via the standard toolbar +
   preview). It appears as a card in the **New** column without a full page
   navigation.
6. Click **Edit** on a card — it flips in place to an inline edit form (title
   input + markdown textarea/toolbar/preview). Change the title and body and
   **Save** — the card updates in place with no page reload.
7. **Cancel** an in-progress edit — the card reverts to its read state without
   saving changes.
8. **Delete** a card — it is removed from the board.

## Lane move (drag-free, dropdown-driven)

9. On a card, use the lane `<select>` (New / Expand / Done / Discard) and pick
   a different lane. The card moves from its old column to the new column
   immediately, with no page navigation.
10. Move a card to **Discard** — it disappears from the visible board until
    "Show discarded" is toggled open, then reappears in the Discard column.

## Promote to Page

11. On a card in any lane, click **Promote**. A new game Page is created with
    the entry's title and body; the entry's lane becomes **Done** and the card
    now shows "Promoted to: <Page title>" instead of the Promote button.
12. Visiting the created page (Pages tab) shows the same title/body as the
    notebook entry had at the time of promotion.
13. From the entry's own show screen, promoting also creates the page and
    updates the same way as from the card.
14. Clicking Promote again on an already-promoted entry is a no-op — no
    duplicate page is created; the existing "Promoted to:" link is shown.

## Access control

15. Every notebook_entries route (index/new/create/show/edit/update/destroy/
    move/promote) redirects a non-GM (active player, removed player, or a GM
    of a *different* game) away with an alert — none of them can view or
    mutate another game's notebook.

## Lifecycle

16. Deleting the game (soft delete → purge) removes all of its notebook
    entries along with the game — `GamePurgeJob` covers `NotebookEntry` the
    same way it covers `Page`/`GameLink`.

## Export

17. When the GM exports their own game, the zip includes a `notebook/`
    directory with one markdown file per entry.
18. When a player exports the same game (their own visible/participating
    slice), the zip does **not** include a `notebook/` directory at all —
    notebook content is GM-eyes-only regardless of general export
    eligibility.

## Regression

19. Existing Scenes / Roster / Files / Pages / Links tabs and their specs are
    unaffected; the tab bar just gains one more pill for the GM.
