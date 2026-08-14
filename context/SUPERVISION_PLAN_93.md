# Card #93 — supervision plan

Branch: `93-policy-capability-naming` off `origin/master` @ `9bfda1f`.

## Wave 0 — foundation (agent, running)

Spec: `context/FOUNDATION_SPEC_93.md`. Establishes GamePolicy capabilities,
renames `is_gm:` across 44 files, documents the convention in ApplicationPolicy
and CLAUDE.md. **Validated in detail by me before any section starts.**

## Wave 1 — sections (parallel agents, git worktrees)

Each owns its policy + controller(s) + views + specs. Boundaries verified
disjoint: view dirs, policy files and system specs do not overlap.

| # | Section | Policy | Controllers | Views |
|---|---------|--------|-------------|-------|
| 1 | Pages | PagePolicy | pages | pages/{edit,new,show} |
| 2 | Scenes | ScenePolicy | scenes, scene_participants | scenes/*, scene_participants/edit |
| 3 | Scene summaries | SceneSummaryPolicy | scene_summaries | scene_summaries/* |
| 4 | Characters | CharacterPolicy, CharacterVersionPolicy | characters, character_versions | characters/*, character_versions/show |
| 5 | Game links | GameLinkPolicy | game_links | game_links/* |
| 6 | Invitations | InvitationPolicy | invitations | — |

## Wave 2 — mine (judgment, not renaming)

Not delegated: each has a behavioural edge a mechanical rename would get wrong.

- **Game files** — `destroy` fetches the record before `authorize`; removing the
  guard turns a non-GM's denial into a not-found. Needs reordering.
- **Members** — `GameMemberPolicy#update?` is `manager? && !record.game_master?`,
  conflating "you are the GM" with "the target isn't the GM".
  `require_manageable_member!` splits them again to recover "Cannot change GM
  status." A non-GM targeting the GM's membership currently gets the wrong
  message. Split into capability + target-eligibility.
- **`require_game_access!`** — 9 controllers, one shared message
  ("You do not have access to this game."), asserted by
  `spec/system/access_control_spec.rb:92` and `game_exports_spec.rb:75`.
  NOT redundant: it gates before `authorize` and yields a distinct message, so
  unlike `require_gm!` it cannot simply be deleted. Cross-cutting → mine.
- **Games** — `GamesController` is also the foundation agent's file
  (dashboard `is_gm:`); `GamePolicy` is the shared surface. Runs last.

## Wave 3 — close out

Full `bundle exec rspec`, mutation via `bin/full-check`,
`bin/quality-metrics --save` ONCE, PR, comment back on Fizzy #93.

## Invariant for every wave

Behaviour does not change. No user-visible string, redirect, or permission
outcome differs — except the two deliberate exceptions in Wave 2 (game files
not-found ordering, game members wrong-message fix), which get explicit specs.
