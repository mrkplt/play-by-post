# Section: Scenes — Fizzy #93

Read `context/SECTION_SPEC_93_COMMON.md` first. Apply its standard tasks here.

## Files you own

- `app/controllers/scenes_controller.rb`
- `app/controllers/scene_participants_controller.rb`
- `app/policies/scene_policy.rb`
- `app/views/scenes/{index,new,show}.html.erb`
- `app/views/scene_participants/edit.html.erb`
- `spec/policies/scene_policy_spec.rb`
- `spec/requests/scenes_spec.rb`
- `spec/requests/scene_participants_spec.rb`
- `spec/system/scenes_spec.rb`

Touch nothing else. Do NOT touch `scene_summaries` — another agent owns it.

## Section detail

`ScenePolicy` is already largely correct — `resolve?`, `manage_participants?`
and `join?` are capability names, and `create?` is the GM-only scene creation
capability. Your work is mostly on the callers. If `create?` inlines `gm?`,
give it a capability name and delegate.

**Two `require_gm!`-family guards in `ScenesController`:**

- `:125 require_gm!` — `only: %i[new create]`, message "Only the GM can create
  scenes.", redirect `game_path(@game)`. Delete per common task 2. Note
  `spec/system/scenes_spec.rb:96` asserts "Only the GM can create scenes" —
  update it.
- `:132 require_gm_to_resolve!` — read it. If it duplicates
  `ScenePolicy#resolve?` (which `#resolve` already authorizes), delete it the
  same way; if it carries a precondition the policy does not express, keep it
  but make it ask the capability. State which you found and why in your report.

`ScenesController:121` — `require_game_access!`. **Leave alone.**

**`SceneParticipantsController`:**

- `:85 require_gm!` — `only: %i[edit update]`, message "Only the GM can edit
  participants.", redirect `game_scene_path`. Delete per common task 2.
  `spec/system/scenes_spec.rb:228` asserts "Only the GM can edit participants"
  — update it.
- `:57` — `if @scene.private? && !policy(@game).update?` inside an action. This
  is a **visibility** question about a private scene, not "may administer the
  game". `ScenePolicy#visible?` already expresses the private-scene gate. Read
  the surrounding code and convert it to the capability that actually matches
  its intent; explain your reading in the report.

Views: `scenes/{index,new,show}` and `scene_participants/edit` call
`policy(@game).update?` for the GameNav flag. Convert to the capability. The
component parameter was already renamed by the foundation pass — read the
component and match its current name.
