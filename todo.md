# TODO

## Features

### Game Files Gallery View
- **Requirements:** [context/requirements/game-files-gallery-view.md](context/requirements/game-files-gallery-view.md)
- **Status:** Not started
- **Summary:** Replace the game files table with a responsive thumbnail gallery grid. Image and PDF thumbnails via ActiveStorage variants (PDF requires poppler). Lightbox modal for preview. Download and GM delete on each card. Add "View Files" link for non-GM players on game page.
- **Key tasks:**
  - [ ] Add `poppler-utils` to Dockerfile and Railway/Nixpacks config
  - [ ] Add thumbnail variant method to `GameFile` model (images + PDF preview)
  - [ ] Replace table layout with CSS grid gallery in `game_files/index.html.erb`
  - [ ] Add file-type placeholder cards for non-thumbnailable files
  - [ ] Add Stimulus controller for lightbox modal (open/close/escape)
  - [ ] Add download button on card and in modal
  - [ ] Add GM delete button on gallery cards
  - [ ] Add "View Files" link for non-GM players on `games/show`
  - [ ] Add system specs for gallery view, lightbox, upload, delete
