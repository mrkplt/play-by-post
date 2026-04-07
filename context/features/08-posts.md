# Scene View & Posts

## Overview

Posts form the narrative thread within a scene. They support markdown, images, OOC designation, time-limited editing, and draft state.

## Requirements

### Scene View
- Posts are flat within a scene (linear thread, not nested replies)

### Post Display
- Each post shows: author display name, timestamp, markdown-rendered body, optional image

### Out-of-Character (OOC) Posts
- Posts can be marked Out-of-Character (OOC); OOC posts are visually distinct
- OOC posts can be filtered out of the scene view
- Users can hide OOC posts entirely via a profile-level preference (hide_ooc)

### Post Editing
- Post authors can edit their post within 10 minutes of creation; the edit window is enforced server-side
- Edit link is visible only while the edit window is open

### Drafts
- Posts support a draft state -- a post can be saved as a draft before publishing

### Markdown & Media
- Markdown formatting with in-browser live preview
- One image attachment per post
- One image attachment per scene

### File & Image Constraints
- Post and scene images: JPG, PNG, GIF, WEBP -- 10 MB limit
- Game files: PDF, DOC, DOCX, TXT, MD, JPG, PNG, GIF, WEBP -- 25 MB limit
