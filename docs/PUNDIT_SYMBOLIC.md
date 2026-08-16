# Pundit Symbolic Verifier

A repo-local symbolic verifier scoped **explicitly and only** to this app's
Pundit pattern. It reads real policy source, translates each public boolean
predicate into a propositional formula over leaf facts, and answers
consistency questions over *all* inputs — reporting concrete counterexamples.

Run it:

```
bin/verify-policies                       # every policy in app/policies
bin/verify-policies app/policies/game_policy.rb
```

## What it is (and isn't)

It is a **decision procedure over the boolean skeleton of a policy**, not a
general Ruby symbolic executor. Our policies are, by convention, capability
predicates that delegate down to private role predicates bottoming out in a
small closed set of world-reading "leaf facts" (`record.game_master?(user)`,
`record.viewable_by?(user)`, `record.member_for(user)&.active?`, ...). That
closed shape is the entire theory, which is why the tool is ~4 small files and
needs no SMT solver.

The solver is **pure-Ruby truth-table enumeration** (`Solver`). Each policy
mentions a handful of leaf facts, so enumerating all `2^n` assignments is
instant and total — it returns every satisfying assignment, so findings come
with concrete witnesses. Being total, the enumeration is its own proof of
correctness: there is no external SAT engine to trust and no heuristic that
could miss a model.

## The contract: public surface is boolean predicates

Every **public** method of a policy must be a boolean predicate. The encoder
**refuses loudly** on anything else (a Symbol/Relation return, control flow,
arithmetic) rather than skipping it silently. A refused *public* method is a
finding: it violates the convention (e.g. `GamePolicy#export_scene_selection`
returns a Symbol — arguably it should not be public surface). `Scope#resolve`
returns a relation and is out of theory by design; modeling it would require a
theory of the database.

## What it reports (no domain axioms)

The verifier assumes **nothing** about which states are reachable — it explores
the full boolean space and surfaces latent assumptions rather than baking them
in:

- **`role_grant_ignores_status`** — a grant that is load-bearing on the
  game_master *role* leaf reaching access alongside a removed/banned *status*.
  This is safe only under an unstated invariant. GamePolicy's own comment
  (`game_policy.rb:82`) states exactly this invariant for `write_access?` /
  `feed?`; the tool derived the same fact from structure alone.
- **`broken_equivalence`** — two predicates the source documents as "the same
  question" (e.g. `show?`/`view?`) that disagree on some input.

Triage each finding as *real bug* vs *intended-but-unstated invariant*.

## Why you can trust it: the faithfulness proof

The verifier is sound only if each formula means the same thing as the real
Ruby method:

```
∀ inputs i,  encode(m).eval(i) == m.call(i)
```

`spec/pundit_symbolic/faithfulness_spec.rb` discharges that `∀` by **exhaustive
differential testing**: for every predicate and every leaf-fact assignment, it
builds a real policy whose world matches the assignment, calls the real method,
and asserts equality with the formula. The leaf-fact domain is finite and
small, so total enumeration is a proof, not a sample — this is the tool's
`by decide`. Corrupting the encoder's leaf map makes the proof fail, so it is
not vacuous.

The spec runs without booting Rails (policies are pure `(user, record)`
objects loaded with only `sorbet-runtime`), keeping it in the fast tier.

## The faithfulness proof is not vacuous — two blind spots it closes

Exhaustive testing is only a proof if the enumeration actually exercises the
dimension a bug would live in. Two ways it could be fooled, both closed:

- **Dropped variables.** If the encoder omits a leaf from a formula, enumerating
  only that formula's own vars would never vary the missing dimension. The proof
  enumerates over the whole policy's leaf-var union, and asserts every leaf the
  real method *read* (recorded by the double) appears in the formula.
- **Short-circuit reads.** `membership&.a? || membership&.b?` only evaluates `b?`
  when `a?` is false, so a dropped `b?` leaf is invisible unless the enumeration
  creates the `¬a? ∧ b?` state. For every `member_for` base the proof forces all
  four status/role leaves (`game_master?`/`active?`/`removed?`/`banned?`) into the
  enumeration, so any dropped status diverges. Corrupting the encoder's membership
  leaf naming makes the proof fail — verified.

## Operationalization

`bin/check-policy-consistency` runs the verifier over every policy and **fails
the build** on any finding, or any *public* refusal not in its `ACCEPTED_REFUSALS`
allowlist. It's wired into `bin/pre-push` (fast tier, ~0.2s, no Rails boot) so it
runs on every push and in CI. Every failure prints **what**, **where** (the
reachable leaf state), and **how to fix** — plus the escape hatch of accepting a
reviewed refusal in the allowlist. Today: 0 findings, 1 accepted refusal
(`export_scene_selection`, Fizzy #104).

The faithfulness proof (`spec/pundit_symbolic/faithfulness_spec.rb`) runs in the
normal RSpec suite, so the gate's verdicts stay backed by the proof.

### The tool's own code is exempt from mutation testing — deliberately

`lib/pundit_symbolic/` is **not** registered in `.mutant.yml`, and that's
intentional: the tool is a separate beast from the application it checks. Its
correctness is guarded by its own faithfulness proof — an exhaustive differential
check of the encoder's output against real policy behavior — which is a stronger,
purpose-built guarantee than generic mutation coverage would give. `.mutant.yml`
and `bin/check-mutant-coverage` govern `app/` (the check only scans `app/`), so
the tool is correctly out of that scope with no gate change needed.

## Scope / status

Generalized across **all 15 policies**; the faithfulness proof (`30 examples`)
holds for every one. The encoder handles: boolean predicates over leaf facts,
delegation (`show? -> view?`), path helpers (`def scene = record.scene` inlined
into leaf paths), `T.must(...)` unwrapping, and receiver paths of any depth
(`record.game.member_for.active?`). Leaf-fact names are derived from the read
path automatically — no per-policy whitelist to maintain.

### Systemic finding

The `role_grant_ignores_status` finding is **not GamePolicy-specific**: the same
GM-role-trusts-without-status pattern recurs across the write-access surface —
`GamePolicy#write_access?`/`#feed?`, `CharacterPolicy#create?`/`#update?`,
`PostPolicy#create?`, `ScenePolicy#join?` (all via the shared `write_member?`
helper). One shared fix, six sites.

### Encodable shapes

Beyond boolean predicates and delegation, the encoder handles:

- **Comparisons** — `record.user == user`, `record.scope == "rss"`. A comparison
  is boolean-valued but its truth is a free fact about the (user, record) pair
  (the tool can't reason about *which* user/value), so it's a leaf named by both
  operands; `!=` is its negation.
- **Guard clauses** — `return false unless COND` contributes `COND &&` to the
  result.
- **Cross-policy delegation** — `OtherPolicy.new(user, record.x).pred?` is
  resolved by `PolicyRegistry`: it inlines `OtherPolicy#pred?`'s formula with its
  `record.` leaves rebased onto `record.x.` So `CharacterVersionPolicy#show?`
  (which routes through `GamePolicy#view?`) becomes `record.character.game.viewable_by?`
  and is checked as one formula. Requires loading via `PolicyRegistry.load_dir`
  (the target policy must be present); `bin/verify-policies` and the proof do.

### Remaining refusal (the one that should stay)

`GamePolicy#export_scene_selection` returns a Symbol — a public non-boolean
method, the genuine convention violation. It's reported, not skipped. A refused
*public* predicate is always a finding to look at, never a silent gap.
