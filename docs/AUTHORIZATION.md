# Authorization Layer — Pundit Migration Plan

Status: **proposed** · Branch: `claude/permission-layer-design-9v3i0v`

## Goal

Replace the ad-hoc, copy-pasted authorization checks scattered across
controllers, models, views, services and the mailbox with a single coherent
layer built on [Pundit](https://github.com/varvet/pundit). One policy object per
domain model owns **all three authorization surfaces** for that model, and the
same object is reused from every tier — controller, view, service, job, mailbox.

Guiding constraint carried over from the design discussion: **policies are
request-free.** They initialize with `(user, record)` and nothing else. Anything
that needs the request (`params`, `action_name`) is resolved in the controller
and handed to the policy as plain values. This is what makes the identical object
usable from a ViewComponent and from `SceneMailbox` — neither has a request.

## The three surfaces

| Surface | Question | Pundit mechanism |
|---------|----------|------------------|
| **Routes / actions** | May this user perform this action on this record? | Policy query methods (`show?`, `resolve?`, `update?`) + `authorize` |
| **Records / collections** | Which records may this user see? Never load one they can't. | `Policy::Scope#resolve` + `policy_scope(Rel).find(id)` (miss → 404) |
| **Fields** | Which attributes may this user set on this action? | `permitted_attributes` (+ `_for_create`/`_for_update`) |

All three live in the same policy class. Field-level is authorization too — the
plan treats it as first-class, not a strong-params afterthought.

---

## Audit — current state

Authorization logic today lives in five places and is duplicated across them.

### 1. Duplicated controller guards (the core mess)

**"Can view this game" (`viewable_by?` = GM ∨ active ∨ removed)** — reimplemented
**seven** times, half via `Game#viewable_by?`, half by inlining the three-way
membership check. Two implementations of one rule that can drift:

- `application_controller.rb:33` `require_active_member!` (write variant)
- `games_controller.rb:186` (`viewable_by?`)
- `game_exports_controller.rb:34` (`viewable_by?`)
- `player_management_controller.rb:41` (`viewable_by?`)
- `character_versions_controller.rb:34-39` (inlined membership check)
- `game_files_controller.rb:59-61` (inlined)
- `scene_summaries_controller.rb:106-108` (inlined)
- `scenes_controller.rb:124-126` (inlined)
- `characters_controller.rb:93-95` (inlined)

**"Must be GM"** — reimplemented **eight** times with divergent redirect targets
and alert strings:

- `games_controller.rb:193` · `scenes_controller.rb:133` ·
  `characters_controller.rb:109` · `scene_participants_controller.rb:81` ·
  `game_members_controller.rb:37` · `invitations_controller.rb:57` ·
  `scene_summaries_controller.rb:115` · `application_controller.rb:34`

**"Active member for write"** — `require_active_member!(game)` in
`ApplicationController`, wrapped by a local `require_active_member_for_write!` in
`posts`, `characters`, `scene_participants`.

### 2. Model predicates (the de-facto shared layer today)

Already reused by controllers *and* views — these become policy bodies:

- `Game#member_for`, `#game_master?`, `#active_member?`, `#viewable_by?` (`game.rb:35-57`)
- `Character#editable_by?(user, game)`, `Character.visibility_rule`, scope `visible_to` (`character.rb:30-46`)
- `Scene#participant?`, scope `visible_to` (`scene.rb:27-47`)
- `Post#editable_by?(user)` (`post.rb:28`)
- `GameMember#game_master?`, `#removed?`, `#banned?` (`game_member.rb:20-35`)
- `NotificationPreference.muted?` (notification gate, membership-adjacent)

### 3. Field-level authorization (currently split from the fields)

- `characters_controller.rb:121` — `permit(:name, :content, :hidden, :user_id)`.
  `:hidden` and `:user_id` are **role-sensitive**; the gating is hand-coded in the
  action body (`characters_controller.rb:21,30`), *separate* from the permit list.
  **This is the canonical field-authz case** and the first target.
- `games_controller.rb:200` `permit(:name, :description, :post_edit_window_minutes)`
- `scenes_controller.rb:207` `permit(:title, :private, :parent_scene_id)`
- `posts_controller.rb:123` `permit(:content, :is_ooc)`
- `scene_summaries_controller.rb:153` `permit(:body)`

### 4. Record-level scopes (already authorized queries)

- `Scene.visible_to(user, game)` and `Character.visible_to(viewer, game)` — these
  are already the "scoped-down query" pattern. They become `Policy::Scope#resolve`
  bodies. Callers: `games_controller`, `scenes_controller`, `game_export_service`.

### 5. Non-HTTP enforcement (proves policies must be request-free)

- `scene_mailbox.rb:45` — reply-by-email participant gate:
  `inbound_email.bounced! unless user && scene.participant?(user)`. No request, no
  controller. Must call the policy directly: `ScenePolicy.new(user, scene).reply_by_email?`.
- `game_export_service.rb:45-61` — membership gate + `:all`/`:participating`
  visibility rule mirroring `Scene.visible_to`.
- `post_digest_job.rb:30` — `NotificationPreference.muted?` gate.
- Views/components: `scenes/show.html.erb:131`, `characters/{new,show,edit}.html.erb`,
  `post_item_component`, `sidebar_component.rb:21`, `nav_drawer_component.rb:39`,
  `player_management/show.html.erb:53`.
- `post_presenter.rb:49` delegates `editable_by?`.

### Explicitly OUT of scope (not user-authenticated / different auth model)

- `users/sessions_controller.rb` — Devise magic-link (authentication, not authz)
- `invitations_controller#accept` — `skip_before_action :authenticate_user!`; token-gated
- `feeds_controller#show` (`GET /feeds`) — `skip_before_action :authenticate_user!`;
  RSS-token-gated. The token is the sole input: an `RssToken` is reverse-looked-up,
  its scope resolved from `game_id`. A game-level token (`game_id` set) renders only
  that game; an account-level token (`game_id` nil) aggregates every game the owner
  is an **active** member of. Membership is re-checked per request, so a removed
  member's live token stops working. A user holds at most one account-level token and
  one per game — enforced by `RssToken`'s `validates :user_id, uniqueness: { scope:
  :game_id }` (a partial DB index backs the account-level case, which the composite
  index cannot since SQLite treats NULLs as distinct). Tokens are managed on the
  profile page; game-scoped tokens are purged with their game by `GamePurgeJob`.
- `webhooks/deploy_controller.rb` — signature-gated webhook, no `current_user`
- `action_mailbox/ingresses/resend/inbound_emails_controller.rb` — Svix-signed ingress

These keep their existing gates. The plan does not touch them.

---

## Target architecture

```
app/policies/
  application_policy.rb        # base: (user, record); default-deny; nested Scope base
  game_policy.rb               # show? edit? update? manage_players? + toggles + Scope + permitted_attributes
  scene_policy.rb              # show? create? resolve? reply_by_email? + Scope + permitted_attributes
  character_policy.rb          # show? create? edit? update? archive? + Scope + permitted_attributes (:hidden/:user_id)
  post_policy.rb               # create? edit? update? + permitted_attributes
  game_file_policy.rb
  scene_summary_policy.rb
  scene_participant_policy.rb
  invitation_policy.rb
  game_member_policy.rb
  user_profile_policy.rb       # show? update? = record.user == user (owner rule)
```

### ApplicationPolicy — use the generator, don't hand-roll

Run `rails g pundit:install`. It generates the canonical `app/policies/application_policy.rb` and we keep its structure verbatim — the default-deny `index?/show?/create?/new?/update?/edit?/destroy?` set, the `new? → create?` / `edit? → update?` aliases, and the nested `Scope` with `protected attr_reader :user, :scope` and a `resolve` that raises until overridden. **These are Pundit's codified opinions; adopt them, don't reinvent.** The only change we layer on is Sorbet: `extend T::Sig`, a `# typed: true` sigil, and a `sig` on `initialize`/`resolve`. We do **not** trim the method set to a custom "just the four I need" list — the full CRUD set with aliases is what makes `authorize @record` infer correctly from `action_name`.

### Worked example — ScenePolicy (all three surfaces)

```ruby
# typed: true
class ScenePolicy < ApplicationPolicy
  sig { returns(T::Boolean) }
  def show? = record.game.viewable_by?(user) && record.visible_to_viewer?(user)

  sig { returns(T::Boolean) }
  def create? = record.game.game_master?(user)

  sig { returns(T::Boolean) }
  def resolve? = record.game.game_master?(user)

  # non-HTTP caller: SceneMailbox
  sig { returns(T::Boolean) }
  def reply_by_email? = record.participant?(user) || record.game.game_master?(user)

  sig { returns(T::Array[Symbol]) }
  def permitted_attributes = %i[title private parent_scene_id]

  # Standard no-arg #resolve; the caller passes the game-scoped relation in.
  class Scope < ApplicationPolicy::Scope
    sig { returns(T.untyped) }
    def resolve = scope.visible_to(user)
  end
end
```

`Scene.visible_to` today takes `(user, game)` because it checks GM status against
the game. Two convention-clean ways to feed the game in, pick one in Phase 2:
1. **Relation carries it** — controller calls `policy_scope(@game.scenes)`; refactor
   `visible_to` to a single-arg scope that reads the game from its own relation
   (`where(game_id:)` context), so `resolve` stays the standard no-arg form.
2. **Pundit's documented escape hatch** — when a scope needs extra context, the
   README sanctions instantiating it directly: `ScenePolicy::Scope.new(user, @game.scenes).resolve`.
   Use this only if (1) is awkward; it's still the gem's blessed path, not a custom one.

**Method-naming convention:** mirror controller action names so `authorize @record`
infers the query from `action_name` (`show?`, `create?`, `update?`, `destroy?`,
`index?`). Only non-RESTful member actions get a custom name, called explicitly:
`authorize @scene, :resolve?`. Field methods follow Pundit's lookup — define
`permitted_attributes_for_create` / `permitted_attributes_for_update` when the two
diverge (see `CharacterPolicy`, `:hidden`/`:user_id`), falling back to the single
`permitted_attributes` when they don't.

### Wiring (ApplicationController)

Straight from Pundit's README — no local invention:

```ruby
include Pundit::Authorization
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
after_action  :verify_authorized
after_action  :verify_policy_scoped, only: :index

def user_not_authorized
  flash[:alert] = "You are not authorized to perform this action."
  redirect_back fallback_location: root_path
end
```

`verify_authorized` runs for every action (the README default); controllers with
genuinely nothing to authorize opt out with `skip_after_action :verify_authorized`
(devise, webhook, and mailbox-ingress controllers — see out-of-scope list). Leave
`pundit_user` at its default (`current_user`); don't repoint it at `Current.user`.

`verify_authorized` / `verify_policy_scoped` are the coherence net: an action that
forgets to call `authorize`/`policy_scope` **fails in tests**, so the layer cannot
be silently bypassed.

### Non-HTTP usage (the reuse payoff)

Pundit's `authorize`/`policy` helpers only exist in controllers/views. Everywhere
else, instantiate directly — same object, request-free:

```ruby
# SceneMailbox
inbound_email.bounced! unless user && ScenePolicy.new(user, @scene).reply_by_email?
# ViewComponent
render_button if ScenePolicy.new(current_user, scene).resolve?
```

### Model predicates — transition, don't rip out

`Scene.visible_to` / `Character.visible_to` **stay** as the query implementation
(`Scope#resolve` delegates to them — keeps their mutation coverage intact and
leaves `game_export_service` working). Boolean predicates (`game_master?`,
`viewable_by?`, `editable_by?`, `participant?`) get their **logic moved into
policies**; during migration the model methods delegate to the policy to avoid
touching every call site at once, then are removed once all call sites are policy
objects.

---

## Repo-specific machinery each phase must satisfy

Non-negotiable given the quality pipeline (see `.claude/CLAUDE.md`):

1. **`.mutant.yml`** — every new policy **and** nested `Scope` class registered
   under `matcher.subjects` (e.g. `ScenePolicy`, `ScenePolicy::Scope`) or the
   `mutant_registration` CI job fails. Policies are pure `(user, record)` →
   boolean, i.e. **ideal mutation targets** — the branch/boundary logic in
   `viewable_by?` (three-way), `visibility_rule`, and `editable_by?` (OR) all
   yield killable mutants. This is the "more mutation testing" upside, realized.
2. **Sorbet** — `# typed: true` on every policy file; explicit `sig` on every
   query method (SimpleDelegator-style passthrough doesn't apply, but Sorbet still
   can't see Pundit's mixed-in `authorize`/`policy`/`policy_scope`/
   `permitted_attributes`). Run `bundle exec tapioca gem pundit` for the RBI; add
   shims for the controller/view helpers if `srb tc` still can't resolve them.
3. **Quality gate** — each new policy file needs ≥80% line / ≥70% branch coverage
   and a sigil. Trivial to hit off the DB with `build_stubbed`; no fixtures.
4. **`context/REQUIREMENTS.md`** — must be updated to describe the authorization
   model before the work is "complete" (CLAUDE.md mandate).
5. **Specs off the DB** — policy specs use `build_stubbed`; `Scope#resolve` specs
   assert on `to_sql` / `where_values_hash` (no INSERTs), per the suite convention.

---

## Phased rollout

Each phase is independently shippable and stays green against the gate + mutation
floor. Order chosen so the first real controller proves all three surfaces end to
end before fanning out.

### Phase 0 — Foundation (no behavior change)
- Add `pundit` to Gemfile; `bundle install`; `tapioca gem pundit`.
- `rails g pundit:install` for the canonical `ApplicationPolicy` + `Scope`; add
  only the Sorbet sigil/`sig`s on top of the generated file — no structural edits.
- Wire `Pundit::Authorization`, `rescue_from`, and the `verify_*` after_actions
  in `ApplicationController` (no controller calls `authorize` yet, so
  `verify_authorized` is not yet enforced — add `except`/opt-in per controller as
  each is migrated).
- Register base classes in `.mutant.yml`; specs for default-deny.
- **Gate:** green, zero behavior change.

### Phase 1 — CharacterPolicy (proves field-level authz first)
The richest surface: record scope (`visible_to`), action predicates
(`editable_by?`, GM-only archive), **and** `:hidden`/`:user_id` field gating.
- `CharacterPolicy` with `show?`, `create?`, `edit?`, `update?`, `archive?`,
  `restore?`, `Scope#resolve` (delegates `Character.visible_to`), and
  `permitted_attributes` that adds `:hidden`/`:user_id` only for GM.
- Migrate `characters_controller`: replace `require_*` guards with `authorize`,
  replace `character_params` permit list with `permitted_attributes(@character)`,
  delete the inline owner/GM branching at `:21,:30`.
- Move view checks (`characters/{new,show,edit}.html.erb`) to
  `policy(@character).…`.
- Policy specs (build_stubbed) killing the `:hidden`/`:user_id` and `editable_by?`
  mutants; register `CharacterPolicy`(+`::Scope`) in `.mutant.yml`.
- **Gate + mutation floor:** green.

### Phase 2 — ScenePolicy + reply-by-email (proves non-HTTP reuse)
- `ScenePolicy` incl. `reply_by_email?`; `Scope` delegating `Scene.visible_to`.
- Migrate `scenes_controller` (`require_game_access!`, `require_gm!`, scope loads)
  and `scene_participants_controller`.
- Repoint `scene_mailbox.rb:45` and the `scenes/show.html.erb` view checks at the
  policy.
- **Gate:** green; mailbox request spec still passes (the one DB-backed routing case).

### Phase 3 — Game family
- `GamePolicy` (show/edit/update/toggles/manage_players + Scope for the index),
  `GameMemberPolicy`, `InvitationPolicy`, `PlayerManagement`/`GameExports`.
- Collapse the seven `viewable_by?`/`require_game_access!` copies and the GM copies
  into `authorize`/`policy_scope`. Delete `ApplicationController#require_active_member!`
  once no caller remains.
- Repoint `sidebar_component`, `nav_drawer_component`, `player_management` views.

### Phase 4 — Remaining resources
- `PostPolicy`, `GameFilePolicy`, `SceneSummaryPolicy`, `CharacterVersionPolicy`,
  `UserProfilePolicy`.
- Migrate `posts`, `game_files`, `scene_summaries`, `character_versions`,
  `profiles` controllers; repoint `post_item_component`, `post_presenter`.

### Phase 5 — Cleanup + enforcement + docs
- Remove now-dead model boolean predicates (keep the scopes); confirm no delegators
  remain.
- Turn on `verify_authorized`/`verify_policy_scoped` for **all** non-devise
  controllers (remove per-controller opt-in).
- `game_export_service` visibility rule → `ScenePolicy::Scope` where it aligns.
- Update `context/REQUIREMENTS.md`; run `bin/quality-metrics --save` to rebaseline
  after the (expected) mutation-coverage increase.
- `bin/full-check` green end to end.

---

## Per-controller migration map

| Controller | Guards today → | Policy target |
|-----------|----------------|---------------|
| `characters` | `require_game_access!`, `require_active_member_for_write!`, `require_edit_access!`, `require_gm!` + inline field gating | `CharacterPolicy` (all 3 surfaces) |
| `scenes` | `require_game_access!`, `require_gm!` + `visible_to` loads | `ScenePolicy` + `Scope` |
| `scene_participants` | `require_gm!`, `require_active_member_for_write!` + private-scene check | `SceneParticipantPolicy` / `ScenePolicy#join?` |
| `posts` | `require_participant!`, `require_active_member_for_write!`, `editable_by?` | `PostPolicy` |
| `games` | `require_game_access!`, `require_gm!` + toggles | `GamePolicy` + `Scope` (index) |
| `game_members` | `require_gm!` | `GameMemberPolicy` |
| `invitations` | `require_gm!` (except accept) | `InvitationPolicy` |
| `player_management` | `viewable_by?` | `GamePolicy#manage_players?` |
| `game_exports` | `viewable_by?` | `GamePolicy#export?` |
| `game_files` | inlined access + `require_gm!` | `GameFilePolicy` |
| `scene_summaries` | inlined access + `require_gm!` | `SceneSummaryPolicy` |
| `character_versions` | inlined access | `CharacterVersionPolicy` / `CharacterPolicy#show?` |
| `profiles` | none (implicitly `current_user`-scoped) | `UserProfilePolicy` — owner rule, **no skip** |

---

## Testing & mutation strategy

- **Policy unit specs** (`spec/policies/*_spec.rb`) — `build_stubbed(:user)` +
  `build_stubbed(:scene)`; assert each query method at the exact role boundary
  (GM / active / removed / banned / non-member) to kill branch mutants. No DB.
- **Scope specs** — assert on `to_sql` / `where_values_hash` (suite convention);
  keep one caller-driven spec so the scope chain actually executes and its mutants
  don't survive unexecuted.
- **Request specs** — largely unchanged; add one per controller asserting a
  forbidden actor gets the redirect/404 (403-path and scope-404-path both covered).
- **`verify_authorized`** guarantees no migrated action silently skips the check.

## Decisions — resolved by Pundit convention

The earlier open questions all have a codified gem answer; we take it rather than
invent a house style.

1. **403 vs 404 split** — Pundit's own idiom already encodes this: `authorize`
   raises `Pundit::NotAuthorizedError` → the single `user_not_authorized` handler
   (flash + `redirect_back`) for the visible-but-forbidden case; loading via
   `policy_scope(rel).find(id)` raises `RecordNotFound` → the existing 404 path for
   the not-in-scope case. No per-controller bespoke copy — one handler, the
   gem-standard message.
2. **Self-scoped surfaces (`profiles`)** — **authorize, don't skip.** A profile has
   an owner and a real rule (you may only touch your own), so it gets a
   `UserProfilePolicy` with `show?`/`update?` = `record.user == user`. "It currently
   only loads `current_user`'s record" is precisely the implicit safety this
   migration removes — it survives only until someone adds a param'd id. Pundit's
   `skip_after_action :verify_authorized` is reserved strictly for controllers with
   genuinely no authenticated user or record concept — the out-of-scope list below
   (devise, webhook, mailbox-ingress), which already skip `authenticate_user!`.
   Nothing user-facing skips.
3. **Field-method naming** — Pundit's lookup convention *is* the answer:
   `permitted_attributes_for_create` / `permitted_attributes_for_update` (it checks
   `permitted_attributes_for_#{action}` first, then `permitted_attributes`). Use
   the action-specific methods where create/update diverge, the single method
   otherwise. No `record.new_record?` branching — that's reinventing the lookup the
   gem already does.
