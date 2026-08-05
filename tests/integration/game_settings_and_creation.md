# Game Creation & Settings — Styling and Details Editing

Covers the redesign of the New Game screen and the surfacing of the game
name/description under Game Settings.

## New Game (games#new)

1. From the dashboard footer, tap **+ New Game**.
2. Expect a dark back-arrow header titled **New Game** inside the mobile frame
   (same chrome as New Scene), not a bare unstyled form.
3. The form shows a **Name** field, a **Description (optional)** textarea, and a
   note that you will become the Game Master.
4. Submitting with a blank name re-renders the framed form with a
   "can't be blank" error inside a tinted error box.
5. Filling Name + Description and tapping **Create game** lands on the new
   game's view; the creator is the GM (settings gear present).

## Game Settings — Game Details (gear → player_management#show)

1. As GM, open a game and tap the **gear** (Game Settings).
2. A **Game Details** section (GM only) shows the game **name** and its
   **description** (or "No description yet." when blank), with an **Edit** link.
3. A non-GM member does not see the Game Details section (same gate as
   "Game Preferences").
4. Tapping **Edit** opens the framed **Edit Game** screen.

## Edit Game (games#edit)

1. The Edit Game screen uses the mobile frame with a back-arrow header, not the
   old unstyled slate card layout.
2. It shows the Name/Description form (**Save Changes**), and the Post Images,
   Character Sheets, AI Scene Summaries, and Manage Players controls, all styled
   with design tokens.
3. Editing the name/description and tapping **Save Changes** returns to the game
   view with the update applied.

## Responsive

- Both screens are exercised through the shared MobileFrame chrome; verify at
  mobile (375) and desktop (1280) that there is no horizontal scroll and the
  form fills the content column.
