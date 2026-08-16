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

## Scope / status

Checkpoint slice: `GamePolicy` fully encoded, verified, and proven faithful.
The encoder generalizes to the other policies as they adopt the same leaf-fact
vocabulary; extend `Encoder#leaf_for` for any new leaf-fact read and add the
policy's documented equivalences to `bin/verify-policies`.
