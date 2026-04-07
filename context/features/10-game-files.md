# Game-Level File Store

## Overview

Each game has a shared file store with a visual gallery interface. The GM manages uploads and deletions; all active and removed members can view and download files.

## Requirements

### Access
- Shared file storage accessible to all active and removed game members (read)
- GM-only upload access
- GM can delete files
- Players can download files

### Gallery View
- Files are displayed as a visual gallery grid of thumbnail cards, not a plain table
- Image files (JPG, PNG, GIF, WEBP) display a thumbnail preview
- PDF files display a first-page preview image as their thumbnail
- Non-previewable files (DOC, DOCX, TXT, MD) display a styled placeholder card showing the file extension prominently
- When a thumbnail cannot be generated (missing dependency, corrupt file), the file-type placeholder is shown instead -- no errors

### Lightbox
- Clicking a card opens a modal lightbox with a larger preview
  - Images: displayed at larger size constrained to the viewport
  - PDFs: first-page preview at larger size (not a full PDF viewer)
  - Non-previewable files: placeholder at larger size plus filename and file size, with emphasis on the download button
  - Lightbox dismisses on backdrop click, Escape key, or close button

### Card Actions
- Each card has a download button that does not trigger the lightbox
- GM cards include a delete button with confirmation; the delete button is visually distinct from the download button

### Upload & Ordering
- The upload form remains at the top of the gallery page, visible to the GM only
- File ordering is upload date descending (newest first)
- Thumbnails are generated lazily on first request; page load is not blocked by image processing
