# Common instructions — Fizzy #93 section conversions

Read this together with your section file. Read
`app/policies/application_policy.rb`'s header comment first — it states the
convention you are applying, and it is authoritative over anything here.

## What you are doing

Policies conflate three ideas. `policy(@game).update?` is used across the app to
mean "is this user the GM", which collapses:

- **System function** — `update?` means "this row may be modified" (Pundit /
  ActiveRecord vocabulary).
- **Role** — `gm?`: a fact about a person. Today it happens to be the answer.
- **Game function (capability)** — what is actually being decided: "may this
  user manage this game's pages / resolve this scene / manage the roster."

The capability is stable; who satisfies it is not. A GM is currently the same
person as the game owner, but that will not always be true — a game may have
many GMs or none, and GM-only functions may later open to specific players or
permission levels. The code must stop hard-coding that identity at every call
site.

**The rule:** capability predicates are the public surface; role predicates
(`gm?`, `owner?`, `write_member?`) stay `private`. `update?`/`destroy?`/`show?`
remain because Pundit's `authorize` infers them from `action_name`, but their
bodies delegate to a capability and must not be borrowed by callers asking a
different question.

**Do NOT introduce a public role predicate** (e.g. `game_master?`) on any
policy. That is the same mistake one level down.

## Available from the foundation pass (already committed)

- `GamePolicy#manage?` — may administer this game
- `GamePolicy#view?` — may see this game

Use these instead of `policy(@game).update?` / `policy(@game).show?` wherever
your section calls them.

## Standard tasks for every section

1. **Name the capability in your policy.** Where `create?`/`update?`/`destroy?`
   inline a private role check, add a capability predicate for the game
   function and express the CRUD predicates in terms of it. Keep role
   predicates private.

2. **Delete your `require_gm!` guard** and its `before_action`. Every guarded
   action already calls `authorize` against a policy enforcing the same rule, so
   the guard is duplication — and it asks a system function to get a role
   answer.

   Denial then flows through Pundit's `rescue_from` in `ApplicationController`:
   flash "You are not authorized to perform this action." and `redirect_back
   fallback_location: root_path`. In request specs there is no Referer, so that
   resolves to `root_path`. **Update every spec asserting the old
   per-controller message or the old redirect target.**

3. **Convert `policy(...).update?` / `policy(...).show?` call sites** in your
   controller and views to the capability. This includes `is_gm:`-style flags
   feeding components — note the foundation pass already renamed the component
   *parameter*; you convert the *call site* that supplies it.

4. **Leave `require_game_access!` ALONE.** It is handled separately and is not
   redundant — it gates before `authorize` and yields a distinct message.

## Two failures a code review already caught — do not repeat them

**A. Convert the controller and its views together, or you create a
split-brain.** The foundation pass converted `games#show`'s view to
`can_manage?` while its controller still loaded the data under
`policy(@game).update?`. Identical today, so nothing failed — but the moment
the two predicates diverge (the whole point of this card) the view renders the
section with `nil` data and raises. If a view you convert displays data that
its controller loads conditionally, **the controller's condition and the view's
condition must ask the same predicate.** Grep your controller for
`policy(` before you finish.

**B. Renaming the caller is not converting the check.** A component method
called `game_master_in?` was left asking `game.member_for(user).game_master?`
directly — bypassing the policy entirely — while its call site got renamed to
`can_manage`. It *looked* converted. Any predicate that answers an
authorization question must route through the policy, not read the model.

**C. The test for "is this policy converted": the private role predicate
(`gm?`) must end up with exactly ONE caller — the capability.** If `gm?`
still appears in three CRUD bodies, you have not finished: granularizing the
rule would mean editing three lines, which is the thing this convention exists
to prevent. Have every CRUD predicate delegate to the capability.

## Constraints

- `# typed: true` minimum on touched `app/` files; components are
  `# typed: strict`. Explicit `sig` on every new policy predicate.
- Every new/renamed policy predicate needs coverage in your
  `spec/policies/*_policy_spec.rb`. Policies are in `.mutant.yml` — an
  unasserted predicate survives mutation and fails the gate.
- The ERB-logic gate forbids ternaries, `||` fallbacks and local assigns in ERB
  **output tags**. If a conversion tempts one, extract a presenter/component
  method.
- `bin/rubocop` lints `.erb` too. No inline `# rubocop:disable` — fix the code.
- **Behaviour must not change** except the denial message/redirect from task 2,
  which is deliberate and must be reflected in specs.
- Verify before reporting: `bin/rubocop`, `bundle exec srb tc`, and
  `SKIP_COVERAGE=1 bundle exec rspec <your policy spec> <your request spec> <your system spec>`.
- Do NOT run `bin/quality-metrics --save`. Do NOT push. Do NOT open a PR.
- Commit on the branch you are given. You are in a git worktree; other agents
  work concurrently — touch ONLY the files your section file lists.

## Report back

The capability names you chose and why; every file touched; verbatim
test/lint/typecheck output; any call site whose intended meaning was ambiguous
and how you read it. Do not claim a command passed unless you ran it.
