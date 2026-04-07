# Scenes

## Overview

Scenes are the primary narrative unit within a game. They can be created in multiple ways, support branching from parent scenes, and are resolved exclusively by the GM.

## Requirements

### Scene List Behaviour
- Scenes ordered most recent first (descending timestamp)
- Scenes sharing the same parent scene are grouped on the same row (parallel branches)
- Private scenes visible only to participants and the GM
- Resolved scenes displayed separately from active scenes

### Quick Scene (from scene view)
- Creates a new scene inheriting all participants and parent from the current scene
- Minimal form: title and description only
- Private flag inherited from the parent scene
- Intended for continuing the narrative with the same group

### New Scene (from scene view or game view)
- Full form: title, description, participant selection, parent scene, private flag, optional image
- When entered from a scene view: pre-populates participants and parent from that scene (GM can change)
- When entered from the game view: starts with the full active player list, no parent pre-selected
- The GM is always included as a participant and cannot be removed
- A scene with only the GM as participant is valid (narration-only)
- Scenes can have one parent or no parent; branching is allowed, merging is not
- Parent scene dropdown includes both active and resolved scenes

### Joining an Existing Scene
- An active game member who is not a participant in a scene can join it themselves
- Join is not available on private scenes or resolved scenes
- The GM cannot join scenes this way (they are always a participant)

### Scene Resolution
- Only the GM can resolve (close) a scene via an "End Scene" action
- Resolution is final and at the GM's sole discretion; players cannot vote or approve
- Resolution presents an optional outcomes text field (what happened, what was gained/lost)
- Resolved scenes display their outcomes prominently
- All scene participants receive a resolution notification email
- The scene toolbar (actions menu) is hidden after a scene is resolved
