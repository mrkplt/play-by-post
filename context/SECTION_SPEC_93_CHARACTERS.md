# Section: Characters — Fizzy #93

Read `context/SECTION_SPEC_93_COMMON.md` first. Apply its standard tasks here.

## Files you own

- `app/controllers/characters_controller.rb`
- `app/controllers/character_versions_controller.rb`
- `app/policies/character_policy.rb`
- `app/policies/character_version_policy.rb`
- `app/views/characters/{edit,new,show}.html.erb`
- `app/views/character_versions/show.html.erb`
- `spec/policies/character_policy_spec.rb`
- `spec/policies/character_version_policy_spec.rb`
- `spec/requests/characters_spec.rb`
- `spec/requests/character_versions_spec.rb`
- `spec/system/characters_spec.rb`

Touch nothing else.

## Section detail

`CharacterPolicy` is already in good shape: `archive?`/`restore?` are
capabilities, `assign_owner?` is field-level authorization, `visible?` is the
hidden-sheet gate, and `write_member?`/`gm?`/`editable?` are correctly private.
Verify nothing public is a role question; if `archive?`/`restore?` inline `gm?`
directly, route them through a named capability.

**`CharactersController` has FIVE guards — most are NOT the tautology.** Read
each before acting:

- `:120 require_gm!` — `only: %i[archive restore]`. This one already asks a
  real capability: `policy(@character).archive?`. Both actions call
  `authorize @character`, which infers `archive?`/`restore?` — so the guard
  duplicates the policy. Delete it per common task 2 and update the spec
  asserting "Only the GM can archive or restore characters."
- `:110 require_visible!` — the hidden-sheet gate, distinct message. **Keep.**
  If it asks a system function, convert it to the capability; do not delete it.
- `:115 require_edit_access!` — asks `policy(@character).update?` for a
  distinct message ("You cannot edit this character."). This is the correct
  question already. Leave the semantics; convert only if it is asking through
  the wrong predicate.
- `:104 require_game_access!` — **leave alone** (handled separately).
- `:125 require_active_member_for_write!` — a write-access gate, not a GM
  gate. **Leave alone** unless it asks a system function for a capability
  answer; say what you found.

Deleting only the `archive`/`restore` guard is the expected outcome here. If
you conclude another guard is also redundant, say so in your report with
evidence — do not delete it on a hunch.

`CharacterVersionsController`: `require_game_access!` at `:36` — **leave
alone**. `CharacterVersionPolicy#show?` calls
`record.character.game.viewable_by?(user)` directly; if the foundation pass
introduced a game-level view capability, consider whether this should express
itself through it rather than reaching through two associations. Use your
judgment and explain it.

Views: `characters/{edit,new,show}` and `character_versions/show` call
`policy(@game).update?` for the GameNav flag; `characters/{edit,new}` call
`policy(@character).assign_owner?` (already a capability — leave);
`characters/show.html.erb:19` calls `policy(@character).update?` to gate an
edit affordance. Convert the GameNav call sites; for the `:19` one, decide
whether "may edit this sheet" is the right capability and say so.
