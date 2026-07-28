# AI Character Portraits — Feature Note

## Idea

Analyze a character's posts across all scenes to generate a prose portrait of who
they are: personality, relationships, defining moments. At end-of-life (character
death, retirement, campaign end) this becomes a eulogy — a narrative obituary drawn
from the actual play record.

## Open Questions

- Who can trigger generation — player, GM, or both?
- Scoped to a single game or across all games a character appeared in?
- Where does it live — on the character sheet? A dedicated page?
- Is it editable after generation?
- Eulogy vs. portrait — same output, different framing, or separate prompts?

## Notes

- Would write to `ai_usages` for token tracking (see AI_USAGE_TRACKING_NOTE.md)
- Depends on character post history — requires resolved scenes or all scenes?
