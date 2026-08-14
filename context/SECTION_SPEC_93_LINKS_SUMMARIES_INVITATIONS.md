# Section: Game links + Scene summaries + Invitations — Fizzy #93

Read `context/SECTION_SPEC_93_COMMON.md` first. Apply its standard tasks to
each of the three areas below. They are grouped because each is small and they
share no files.

## Files you own

- `app/controllers/game_links_controller.rb`
- `app/controllers/scene_summaries_controller.rb`
- `app/controllers/invitations_controller.rb`
- `app/policies/game_link_policy.rb`
- `app/policies/scene_summary_policy.rb`
- `app/policies/invitation_policy.rb`
- `app/views/game_links/{edit,index,new}.html.erb`
- `app/views/scene_summaries/index.html.erb`
- `spec/policies/{game_link,scene_summary,invitation}_policy_spec.rb`
- `spec/requests/{game_links,scene_summaries,invitations}_spec.rb`
- `spec/system/game_links_spec.rb`

Touch nothing else. Do NOT touch `scenes` or `scene_participants` — another
agent owns those.

## Game links

`GameLinkPolicy`: `create?`/`update?`/`destroy?` inline `gm?`; `index?` is
`viewable?`. Name the write capability ("may manage this game's links") and
delegate.

`:80 require_gm!` — `only: %i[new create edit update destroy]`, message "Only
the GM can manage links.", redirect `game_game_links_path(@game)`. Delete per
common task 2.

`:75 require_game_access!` — **leave alone.**

Views: `game_links/{edit,index,new}` call `policy(@game).update?` for the
GameNav flag. Convert.

## Scene summaries

`SceneSummaryPolicy`: `create?`/`update?`/`destroy?` inline `gm?`, which
reaches `record.scene.game.game_master?(user)`. Name the capability ("may
manage this scene's summary" or similar) and delegate.

`:98 require_gm!` — `only: %i[new create edit update destroy]`, message "Only
the GM can manage summaries.", redirect `@game`. Delete per common task 2.

`:87 require_game_access!` and its helper `game_access_granted?` (`:92`, which
calls `policy(@game).show?`) — **leave alone**; handled separately.

`:104 require_resolved_scene!` — a scene-state precondition, not an
authorization question. **Leave alone.**

Note `#index` is deliberately outside `verify_authorized` (see the controller's
`except: :index`). Do not change that.

Views: `scene_summaries/index.html.erb` supplies a GameNav flag. Convert its
call site.

## Invitations

`InvitationPolicy`: `create?`/`destroy?`/`resend?` inline `gm?`. Name the
capability ("may manage this game's invitations") and delegate.

`:67 require_gm!` — asks `policy(@game).update?`, message "Only the GM can
manage invitations.", redirect `game_path(@game)`. Delete per common task 2.

Check which actions it guards and confirm each calls `authorize` before you
delete it — if any action does NOT authorize, deleting the guard would open a
hole. Say explicitly in your report that you verified this. `resend?` in
particular is a non-CRUD action: confirm it authorizes with the right query.

Invitations have no `require_game_access!` and no views of their own in this
section (the accept flow is public and out of scope — do not touch
`invitations#accept` or its policy path).
