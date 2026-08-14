# Section: Members — Fizzy #93

Convert `GameMembersController` + `PlayerManagementController` +
`GameMemberPolicy` to the capability convention. Read
`app/policies/application_policy.rb`'s header comment first — it states the rule
you are applying. `GamePolicy#manage?` (administer this game) and
`GamePolicy#view?` already exist from the foundation pass.

## Files you own

- `app/controllers/game_members_controller.rb`
- `app/controllers/player_management_controller.rb`
- `app/policies/game_member_policy.rb`
- `spec/policies/game_member_policy_spec.rb`
- `spec/requests/` — the game_members and player_management request specs
- `spec/system/player_management_spec.rb`

Touch nothing else. Other agents own other sections concurrently.

## Task 1 — THE CONFLATION (the substance of this section)

`app/policies/game_member_policy.rb` currently reads:

```ruby
def update?
  manager? && !record.game_master?
end
```

That single predicate answers **two unrelated questions** at once:

1. **A capability:** "may this user administer this game's roster?"
   (`manager?` — a role check on the *acting* user)
2. **A target-eligibility rule:** "is the member being changed someone whose
   status may be modified at all?" (`!record.game_master?` — a fact about the
   *target* record; the GM's own membership is never modifiable, by anyone)

`GameMembersController` then has to pull them apart again to produce a useful
message. It currently does this with TWO guards:

```ruby
before_action :require_gm!               # line 7  — the capability
before_action :require_manageable_member!, only: :update   # line 9 — eligibility

def require_manageable_member!
  return if policy(@member).update?
  redirect_to game_player_management_path(@game), alert: "Cannot change GM status."
end

def require_gm!
  unless policy(@game).update?
    redirect_to game_path(@game), alert: "Only the GM can manage players."
  end
end
```

### The bug this creates

`require_gm!` currently masks the problem. If you delete it naively — as the
other sections delete theirs — a **non-GM** targeting the **GM's own
membership** falls through to `require_manageable_member!`, whose predicate
`policy(@member).update?` is false for BOTH reasons. That user gets
**"Cannot change GM status."** — which is wrong. They are not authorized at
all; the target's eligibility is none of their business, and the message leaks
a rule about a record they may not touch.

### Required fix

Split the predicate so each question has its own name:

- A **capability** predicate — "may this user manage this game's members"
  (delegates to the private `manager?` role check).
- `update?` — keeps BOTH conditions, because Pundit's `authorize` infers
  `update?` from `action_name` and the action genuinely requires both. Express
  it as `capability && target-is-eligible`, not as a re-inlined role check.
- Optionally a named predicate for the target-eligibility half, if it makes
  `require_manageable_member!` read clearly.

Keep `manager?` private.

Then in the controller:
- Delete `require_gm!`. The action's `authorize @member` must enforce the
  **capability** — so it needs to authorize the capability explicitly (pass the
  query, e.g. `authorize @member, :<capability>?`), because plain
  `authorize @member` infers `update?`, which fails for the wrong reason and
  produces the wrong message.
- Keep `require_manageable_member!` for its specific "Cannot change GM status."
  message, but it must now run only for users who ALREADY hold the capability —
  otherwise the ordering bug above returns.

Order matters: **authorization first, eligibility second.** A user without the
capability must never see an eligibility message.

## Task 2 — required specs

These pin the behaviour and will be checked. Add to the request spec:

1. **A non-GM targeting the GM's own membership** gets the authorization
   outcome — flash "You are not authorized to perform this action." — and NOT
   "Cannot change GM status." *(This is the bug fix. It must fail against the
   naive implementation.)*
2. **The GM targeting their own membership** still gets
   "Cannot change GM status." and the redirect to
   `game_player_management_path`. *(Unchanged behaviour.)*
3. **A non-GM targeting an ordinary player's membership** gets the
   authorization outcome and the member's status is unchanged.
4. **The GM targeting an ordinary player** still succeeds.

Note: deleting `require_gm!` changes denial to Pundit's `rescue_from` —
flash "You are not authorized to perform this action.", `redirect_back
fallback_location: root_path` (which is `root_path` in request specs, as there
is no Referer). Update any existing spec asserting the old
"Only the GM can manage players." message or the old `game_path` redirect.

## Task 3 — PlayerManagementController

`app/controllers/player_management_controller.rb:15` uses
`policy(@game).update?` to decide whether to load the member roster — a
capability question ("should this screen show the management sections"), asked
through a system function. Switch it to the game-level capability.

Its `require_access!` (line 41) already asks `policy(@game).manage_players?` —
that is a correctly-named capability. Leave it.

## Constraints

- `# typed: true` minimum on touched `app/` files. Explicit `sig` on every new
  policy predicate.
- Every new/renamed policy predicate needs `spec/policies/game_member_policy_spec.rb`
  coverage — policies are in `.mutant.yml`, so an unasserted predicate survives
  mutation.
- Behaviour changes ONLY where this spec says so (the wrong-message fix and the
  denial message from deleting `require_gm!`). Everything else identical.
- Verify: `bin/rubocop`, `bundle exec srb tc`, then
  `SKIP_COVERAGE=1 bundle exec rspec spec/policies/game_member_policy_spec.rb spec/requests spec/system/player_management_spec.rb`.
- Do NOT run `bin/quality-metrics --save`. Do NOT push. Do NOT open a PR.
- Commit on the branch you are given.

## Report back

The predicate names you chose and how you split them; how you ordered
authorization vs eligibility in the controller and why; the verbatim text of
the four required specs; confirmation that spec #1 fails against the naive
implementation (say so explicitly if you checked); every file touched; verbatim
test/lint/typecheck results.
