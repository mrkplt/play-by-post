# Player Management

## Overview

The GM manages game membership through invitations, player removal (amicable departure), and player banning (adversarial, permanent revocation).

## Requirements

### Invitations
- GM invites players by email
- Invited player receives a magic link email; no existing account required
- GM can view all pending invitations
- GM can cancel or resend a pending invitation
- Invitation acceptance creates or links the player's account and adds them to the game

### Player Removal (amicable departure)
- GM can remove a player from a game
- Removed players retain read-only access to the game, game files, and all scenes they participated in
- Removed players can view their own character sheet (read-only)
- Removed players cannot post, create scenes, or be added to new scenes
- Removed players no longer receive notifications
- The game remains on the removed player's dashboard with a "Former" indicator
- The character roster shows a "Removed" status for the player

### Player Banning (adversarial, GM's discretion)
- GM can ban a player -- distinct from removal, with a separate confirmation that communicates permanent access revocation
- Banned players lose all access: game, scenes, posts, characters, files, everything
- The game disappears from the banned player's dashboard entirely
- Banned players no longer receive notifications
- The character roster shows a "Banned" status visible only to the GM
