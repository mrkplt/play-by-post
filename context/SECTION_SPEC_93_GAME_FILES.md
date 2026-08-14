# Section: Game files — Fizzy #93

Convert `GameFilesController` + `GameFilePolicy` to the capability convention.
Read `app/policies/application_policy.rb`'s header comment first — it states the
rule you are applying. `GamePolicy#manage?` (administer this game) and
`GamePolicy#view?` (may see this game) already exist from the foundation pass.

## Files you own

- `app/controllers/game_files_controller.rb`
- `app/policies/game_file_policy.rb`
- `spec/policies/game_file_policy_spec.rb`
- `spec/requests/game_files_controller_spec.rb` (confirm the real filename)
- `spec/system/game_files_spec.rb`

Touch nothing else. Other agents own the other sections concurrently.

## Task 1 — name the capability in `GameFilePolicy`

`create?` and `destroy?` both inline the private `gm?` role check. Give the
policy a capability predicate for the game function ("may manage this game's
files") and express `create?`/`destroy?` in terms of it. Keep `gm?` private.

## Task 2 — delete `require_gm!`

`app/controllers/game_files_controller.rb:67` defines:

```ruby
def require_gm!
  unless policy(@game).update?
    redirect_to game_path(@game), alert: "Only the GM can manage files."
  end
end
```

It is applied `only: %i[create destroy]`. Both actions already call `authorize`
against `GameFilePolicy`, which enforces the same rule — so this guard is pure
duplication, and it asks `update?` (a system function: "may this row be
modified") to get a GM answer. Delete the guard and its `before_action`.

Denial then flows through Pundit's `rescue_from` in `ApplicationController`,
which sets the flash to "You are not authorized to perform this action." and
does `redirect_back fallback_location: root_path`. In request specs there is no
Referer, so that resolves to `root_path`. **Update any spec asserting the old
message or the old `game_path` redirect.**

Leave `require_game_access!` (line 62) ALONE — it is being handled separately
and is not redundant.

## Task 3 — THE ORDERING BUG (the part that needs care)

`#destroy` currently reads:

```ruby
def destroy
  game_file = @game.game_files.find(params[:id])   # ← runs FIRST
  authorize game_file
```

Today `require_gm!` rejects a non-GM *before* the action body runs, so the
`find` is never reached by an unauthorized user. Once you delete the guard, a
non-GM's request reaches `find` first. For a **bad id**, `find` raises
`ActiveRecord::RecordNotFound`, which `ApplicationController` rescues into
"That could not be found." + `root_path`.

The result: a non-GM probing a non-existent file id learns it does not exist,
instead of being told they are not authorized. That is both the wrong answer
and a small information disclosure — an unauthorized user should not be able to
distinguish "no such file" from "not allowed", because that difference reveals
which ids exist.

**Fix:** authorize before the record lookup, so authorization is decided
without depending on whether the record exists. `authorize` needs a record to
find the policy — use a policy-bearing instance that does not require the
lookup to succeed (e.g. `@game.game_files.new`, as `#create` already does),
then perform the `find` afterwards for the actual deletion.

**Required spec** (add to the request spec): a non-GM issuing
`DELETE` with a **nonexistent** game-file id must get the authorization
outcome, NOT the not-found outcome. Assert on the flash — it must be
"You are not authorized to perform this action." and must NOT be
"That could not be found." Without this assertion the mutation gate will not
protect the ordering, and a future refactor will silently reintroduce it.

Also keep/add a spec that a **GM** deleting a nonexistent id still gets the
not-found behaviour — that path is legitimate and must not change.

## Constraints

- `# typed: true` minimum on touched `app/` files. Explicit `sig` on every new
  policy predicate.
- Every new policy predicate needs `spec/policies/game_file_policy_spec.rb`
  coverage — policies are in `.mutant.yml`, so an unasserted predicate survives
  mutation.
- No behaviour change other than: (a) the denial message/redirect from deleting
  `require_gm!`, and (b) the ordering fix in Task 3. Both are deliberate and
  both need specs.
- Verify: `bin/rubocop`, `bundle exec srb tc`, then
  `SKIP_COVERAGE=1 bundle exec rspec spec/policies/game_file_policy_spec.rb spec/requests spec/system/game_files_spec.rb`.
- Do NOT run `bin/quality-metrics --save`. Do NOT push. Do NOT open a PR.
- Commit on the branch you are given.

## Report back

The capability name you chose; how you reordered `#destroy` and why that choice
of policy-bearing record; the exact text of the two ordering specs you added;
every file touched; verbatim test/lint/typecheck results. Do not claim a
command passed unless you ran it.
