# Section: Pages — Fizzy #93

Read `context/SECTION_SPEC_93_COMMON.md` first. Apply its standard tasks here.

## Files you own

- `app/controllers/pages_controller.rb`
- `app/policies/page_policy.rb`
- `app/views/pages/{edit,new,show}.html.erb`
- `spec/policies/page_policy_spec.rb`
- `spec/requests/pages_spec.rb`
- Any pages system spec (check `spec/system/` for one)

Touch nothing else.

## Section detail

`PagePolicy`: `create?`/`update?`/`destroy?` each inline the private `gm?`.
Pages are readable by every non-banned member (`show?` → `viewable?`) and
writable only by the GM — name the write capability for the game function
("may manage this game's pages") and express the CRUD predicates through it.

`PagesController:77` — `require_gm!`, applied
`only: %i[new create edit update destroy]`, message "Only the GM can manage
pages.", redirect `game_path(@game, anchor: "pages")`. Delete it per common
task 2 and update the specs asserting that message/redirect.

`PagesController:72` — `require_game_access!`. **Leave alone.**

Views: `pages/{edit,new,show}.html.erb` call `policy(@game).update?` to supply
the GameNav flag, and `pages/show.html.erb:11` calls `policy(@page).update?`
for `Shared::PageDetailComponent`. Convert both kinds to the capability. The
component's parameter was already renamed by the foundation pass — read the
component to see its current parameter name and match it.
