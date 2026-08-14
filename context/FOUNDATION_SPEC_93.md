# Foundation pass — Fizzy #93: capability naming in Pundit policies

This is the **foundation commit only**. Do not touch any section's controller,
views, or specs beyond what is listed here. Nine section agents follow and will
convert their own areas against the convention you establish.

Branch is already created and checked out: `93-policy-capability-naming`, based
on `origin/master` at `9bfda1f`.

## The problem being fixed

`policy(@game).update?` is used in ~29 places to mean "is this user the GM."
That single expression collapses three distinct ideas:

- **System function** — `update?` is Pundit/ActiveRecord vocabulary meaning
  "this row may be modified."
- **Role** — `gm?` is a domain fact about a person: "this user is a Game
  Master." Today it happens to be the answer.
- **Game function (capability)** — what is actually being decided: "may this
  user manage this game's pages / resolve this scene / manage the roster."

The capability is the stable concept; who satisfies it is not. Because the code
writes the capability *as* the role and asks it through the system function, the
capability is never named — so it cannot be changed in one place.

**Domain understanding to encode:** a GM is currently the same person as the
game owner, but that will not always be true. A game owner may not be a GM; a
game may have many GMs, or none; GM-only functions may later granularize to
permission levels, to specific players, or to all players. Nothing about that
is being implemented now — the point is that the code must stop asserting
`owner == GM == can-do-everything` at every call site.

## Establish the pattern (this is the deliverable)

**Capability predicates are the public surface.** Controllers, views,
components and presenters ask only capability questions, named for the game
function.

**Role predicates stay private inside the policy** — `gm?`, `owner?`,
`write_member?`. They are the *implementation* of a capability: the one line
that changes when a rule granularizes.

**`update?`/`destroy?`/`show?` remain** where Pundit's `authorize` infers them
from `action_name`, but their bodies should read as a capability — they must
not be borrowed by callers asking a different question.

**Do NOT add a public `GamePolicy#game_master?`.** That is the same mistake one
level down: it keeps a *role* on the public surface, so every call site would
still hard-code "the GM is the one who can do this."

### Precedent already in this repo — follow it, don't reinvent

These are already correct and are the model:

- `PostPolicy#participate?` / `#mark_read?` — capability names, `write_member?`
  private (`app/policies/post_policy.rb`)
- `GamePolicy#manage_players?` / `#export?` / `#write_access?`
  (`app/policies/game_policy.rb`)
- `ScenePolicy#manage_participants?` / `#resolve?` / `#join?`
  (`app/policies/scene_policy.rb`)
- `CharacterPolicy#assign_owner?` (field-level authorization)
- `NotebookEntryPolicy#manage?` — added in PR #222, the worked example for
  "an action that is not CRUD names its own capability"

## Your tasks — exactly these, nothing else

### 1. `GamePolicy` — add the game-level capabilities

Add public capability predicates for the questions the ~29 `policy(@game).update?`
call sites are actually asking. At minimum a general "may administer this game"
capability that the section agents can call. Name it for the game function.
Keep `gm?` private. `update?` stays (Pundit infers it for `GamesController#edit/update`)
but should be expressed in terms of the capability, not duplicate the role check.

Also consider the `policy(@game).show?` family: 8 call sites use it via
`require_game_access!` to mean "may view this game." That is the same
conflation and **is in scope** — give it a capability name too.

### 2. `Shared::GameNavComponent` and the `is_gm:` parameter — rename to a capability

`is_gm:` is a role name in a component's public API — exactly the mistake this
card is about. Rename it to a capability across the codebase.

**This is deliberately part of the foundation, not the sections**, because
`is_gm` spans 44 files (8 components, 2 presenters, 20 views, 14 specs) and
would collide if sections did it independently. Full list:

```
app/components/shared/gallery_component.{rb,html.erb}
app/components/shared/game_card_component.rb
app/components/shared/game_links_list_component.rb
app/components/shared/game_nav_component.rb
app/components/shared/game_pages_list_component.rb
app/components/shared/page_detail_component.rb
app/components/shared/scene_summary_component.{rb,html.erb}
app/components/shared/sidebar_component.html.erb
app/presenters/game_presenter.rb
app/presenters/scene_presenter.rb
app/controllers/games_controller.rb (line 48, `is_gm:` in the dashboard hash)
app/views/**: character_versions/show, characters/{edit,new,show},
  game_files/index, game_links/{edit,index,new}, games/{index,show},
  notebook_entries/{edit,index,new}, pages/{edit,new,show},
  scene_participants/edit, scene_summaries/index, scenes/{index,new,show}
spec/components/previews/shared/gallery_component_preview.rb
spec/components/shared/{gallery,game_card,game_links_list,game_nav,
  game_pages_list,page_detail,scene_summary}_component_spec.rb
spec/presenters/scene_presenter_spec.rb
spec/requests/scenes_spec.rb
```

Pick ONE name and apply it uniformly. The parameter describes what the holder
may do, not who they are.

**Leave the `policy(@game).update?` call sites that feed this parameter alone**
where they live in a section's views — sections convert those. Your job is the
parameter name and the component/presenter/spec side. Where a view only needs
the parameter renamed, rename it; do not also restructure that view.

### 3. `ApplicationPolicy` — document the convention in a comment

A short comment block stating the rule: capabilities public, roles private,
CRUD predicates for `authorize` inference only.

### 4. `.claude/CLAUDE.md` — write the pattern into the conventions

Add a subsection under **Conventions** (near "Presenters & ViewComponents")
capturing:

- The three-way distinction (system function / role / game function)
- The owner-vs-GM domain understanding above
- The rule: capabilities public, roles private
- That `policy(x).update?` must not be used as a stand-in for "is GM"
- The `is_gm:` → capability rename as the view-layer instance of the rule
- A pointer to the precedent policies listed above

Match the file's existing voice: direct, evidence-first, no hedging.

## Constraints

- `# typed: true` minimum on touched `app/` files; components are
  `# typed: strict`. Every new policy predicate needs an explicit `sig`.
- Every new/renamed policy predicate needs spec coverage in
  `spec/policies/*_policy_spec.rb`. Policies are in `.mutant.yml` — an
  unasserted predicate will survive mutation.
- Component parameter renames must update the component spec AND any Lookbook
  preview in `spec/components/previews/`.
- **Behaviour must not change.** This is a naming and indirection change. No
  user-visible string, redirect, or permission outcome should differ.
- Run `bin/rubocop`, `bundle exec srb tc`, and
  `SKIP_COVERAGE=1 bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"`
  before reporting done. Then run the full `bundle exec rspec` — system specs
  included — because `is_gm` reaches views.
- Do NOT run `bin/quality-metrics --save`; the baseline is updated once at the
  end of the whole card.
- Commit on the current branch. Do not push. Do not open a PR.

## Report back

State: the capability names you chose and why; the `is_gm:` replacement name;
every file touched; the exact test/lint/typecheck results; and anything you
found that the section agents must know (especially any call site whose
intended meaning was ambiguous, and how you read it).
