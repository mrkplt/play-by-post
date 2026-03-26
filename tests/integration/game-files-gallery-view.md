# Game Files Gallery View - Integration Testing Plan

## Prerequisites
- Local dev server running (`bin/dev` or `rails server`)
- At least one game with a GM user and a player user
- Test files available: a JPEG image, a PNG image, a PDF, a .txt file, a .docx file

## Test Scenarios

### 1. Gallery Grid Display (REQ-004)
- [ ] Navigate to game files page as GM
- [ ] Verify files display in a CSS grid (not a table)
- [ ] Verify grid shows 3-4 columns on desktop viewport
- [ ] Resize browser to mobile width — verify grid collapses to 2 columns, then 1
- [ ] Verify cards are uniformly sized

### 2. Image Thumbnails (REQ-001)
- [ ] Upload a JPEG image as GM
- [ ] Verify the image displays as a thumbnail in the gallery card
- [ ] Verify thumbnail fits within the card (not stretched/distorted)
- [ ] Upload a PNG and WebP image — verify thumbnails render

### 3. PDF Thumbnails (REQ-002)
- [ ] Upload a PDF file as GM
- [ ] Verify the first page renders as a thumbnail preview
- [ ] If poppler is not installed locally, verify a file-type placeholder shows instead (no error)

### 4. File-Type Placeholders (REQ-003)
- [ ] Upload a .txt file and a .docx file
- [ ] Verify each shows a placeholder card with the file extension displayed prominently (e.g., "TXT", "DOCX")
- [ ] Verify placeholder cards are the same dimensions as thumbnail cards

### 5. Filename Display (REQ-005)
- [ ] Verify each card shows the filename below the thumbnail
- [ ] Upload a file with a very long filename
- [ ] Verify long filename is truncated with ellipsis
- [ ] Hover over the truncated filename — verify full name appears in tooltip

### 6. Lightbox Modal (REQ-006)
- [ ] Click on an image card — verify a modal overlay opens with larger image
- [ ] Verify the modal shows the filename
- [ ] Verify the modal has a close button — click it, modal closes
- [ ] Open modal again — click the backdrop, modal closes
- [ ] Open modal again — press Escape, modal closes
- [ ] Verify background page does not scroll while modal is open
- [ ] Click on a PDF card — verify modal shows first-page preview at larger size
- [ ] Click on a .txt card — verify modal shows file-type placeholder with filename and file size

### 7. Download Button (REQ-007)
- [ ] Verify each gallery card has a visible download button/link
- [ ] Click the download button on a card — verify file downloads (browser downloads, not navigates)
- [ ] Verify clicking download does NOT open the lightbox
- [ ] Open lightbox modal — verify it has a download button
- [ ] Click download in modal — verify file downloads

### 8. GM Delete (REQ-008)
- [ ] As GM, verify each card has a delete button
- [ ] Verify delete button is visually distinct from download button
- [ ] Click delete — verify confirmation dialog appears
- [ ] Confirm delete — verify file is removed and flash notice shown
- [ ] As player, verify no delete buttons are visible

### 9. Upload Form (REQ-009)
- [ ] As GM, verify upload form appears above the gallery grid
- [ ] Upload a file — verify it appears as the first card in the gallery
- [ ] As player, verify upload form is not visible

### 10. Game Show Files Section (REQ-010)
- [ ] As GM, visit game show page — verify "Manage Files" link is present
- [ ] As player, visit game show page — verify "View Files" link is present
- [ ] Click "View Files" as player — verify it navigates to the gallery page
- [ ] Verify the compact file list on game show is unchanged

### 11. Performance (REQ-012)
- [ ] Verify gallery page loads quickly (thumbnails load lazily via ActiveStorage URLs)
- [ ] Upload a new file — verify no delay from thumbnail generation during upload
