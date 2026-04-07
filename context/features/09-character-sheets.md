# Character Sheets

## Overview

Characters belong to players within a game. Sheets are plain-text documents with automatic version history and visibility controls managed by both players and the GM.

## Requirements

### Character Ownership
- A player can have multiple characters per game (main characters, retired characters, GM-created NPCs)
- When a player joins a game they do not yet have a character; they are prompted to create one but it is not required immediately

### Character Creation & Editing
- Character creation requires a name; sheet content starts empty and can be filled in at any time
- Sheet content is plain text, rendered monospaced with whitespace preserved
- Characters can be marked inactive; inactive characters are hidden by default from the roster and dashboard
- The GM can create a character on behalf of any player
- The GM can edit any character sheet in their game

### Visibility
- Character sheets are visible to all game participants by default
- Players can mark their own sheet as hidden from other players
- The GM can hide all character sheets game-wide (overrides individual visibility)
- The GM can always see all sheets regardless of visibility settings

### Version History
- Every save of a character sheet automatically creates a version snapshot
- Version history shows: date, who made the change, and the full sheet content at that point
- Players and the GM can browse and view any historical version
- No diff view required for v1; full-text view per version is sufficient
