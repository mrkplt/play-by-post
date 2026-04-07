# Notifications & Email

## Overview

The platform communicates with users via email notifications for game events, supports reply-by-email to create posts, and provides per-scene notification preferences.

## Requirements

### Email Types
1. **Game invitation** -- sent when GM invites a player
2. **New scene** -- sent to all participants when a scene is created (except the creator)
3. **Post digest** -- sent to participants who haven't visited a scene in 24+ hours, showing posts since their last visit (up to 10 posts, then "and N more..."); not sent if the participant authored all recent posts and there is nothing new from others
4. **Scene resolution** -- sent to all participants when a scene is resolved, includes outcomes text
5. **Magic link login** -- sent on sign-in request

### Reply-by-Email
- Notification emails include a reply-to address encoding the scene ID
- Replying to a notification email creates a post in that scene
- The sender must be a current scene participant; invalid senders are rejected
- Email content is cleaned before posting (quoted text, signatures, and formatting artifacts are stripped)
- Email-to-post always creates in-character posts; OOC posting requires the web interface
- If content cleaning fails after retries, the post is created from the raw email body and the sender is notified

### Notification Preferences
- Per-scene toggle: each participant can opt out of notifications for any scene they are in
- Absence of a preference record means notifications are enabled (opt-out model)
- Toggle accessible from the scene view and from active scene cards on the game view
- Removed and banned players no longer receive notifications
