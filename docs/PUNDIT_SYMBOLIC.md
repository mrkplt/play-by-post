# Pundit Symbolic Verifier

A repo-local, **declaration-driven** symbolic verifier scoped explicitly to this
app's Pundit pattern. Each policy's intended authorization invariants are
declared in a central contract (`config/policy_invariants.yml`); the tool reads
real policy source, translates each public predicate into a propositional
formula over leaf facts, and **proves the declared invariants hold** over all
inputs — reporting concrete counterexamples.

The tool does **not invent invariants**. It checks exactly what the contract
declares. What makes that trustworthy rather than a silent gap is three enforced
properties:

1. **Declaration coverage** — every policy MUST have a contract entry. A policy
   with none fails the build; the gate prints a scaffold and tells the agent to
   **consult the user** (authorization intent is a human decision, not something
   the tool derives).
2. **No drift (bijection)** — every public predicate must be accounted for in
   its declaration (named by an invariant, or listed `unconstrained`), and no
   declaration may name a predicate that doesn't exist. Enforced both
   directions, so declaration and code cannot drift apart for even one commit.
3. **Verification** — each declared invariant is proved against the encoded
   formulas; a violation fails the build with a counterexample.

Run it:

```
bin/check-policy-consistency              # the gate: coverage + no-drift + verify
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

## The declaration contract

`config/policy_invariants.yml` is the whole authorization contract in one
reviewable place. Per policy:

```yaml
GamePolicy:
  invariants:
    - equivalent: [show?, view?]
    - no_status_blind_grant: write_access?
  unconstrained: [create?]   # deliberately has no declared property
```

Invariant types (`lib/pundit_symbolic/invariants.rb`), each compiled to a SAT
query over the encoded formulas:

| Type | Meaning |
|---|---|
| `equivalent: [a, b]` | a and b agree on every input |
| `implies: [a, b]` | a grants ⇒ b grants |
| `mutually_exclusive: [a, b]` | never both true |
| `always: pred` / `never: pred` | pred is constant true / false |
| `no_status_blind_grant: pred` | pred must not grant via a GM role while ignoring that membership's status (the multi-game-master leak) |

`unconstrained` is a first-class, reviewed "this predicate has no declared
property" — it satisfies the bijection *visibly*, so a free predicate is a
deliberate line in the contract, never a silent gap. Adding a new invariant
*type* (a new kind of property) is a human change to the invariant library; the
tool never invents one.

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

`bin/check-policy-consistency` is the gate, wired into `bin/pre-push` (fast tier,
~0.2s, no Rails boot) and CI. It fails the build on:

- an **undeclared policy** — prints a scaffold and tells the agent to consult the
  user;
- **drift** — a public predicate not accounted for, or a stale declaration entry;
- a **violated invariant** — with a counterexample;
- an unaccepted **public refusal** — a public non-boolean method (`ACCEPTED_REFUSALS`
  holds reviewed exceptions; today just `export_scene_selection`, Fizzy #104).

Every failure prints **what**, **where** (the reachable leaf state), and **how to
fix**. On success it states plainly that it verified *exactly the declared
contract* — so an agent can't mistake "OK" for "fully proven": it means the
authored invariants hold, coverage is complete, and nothing drifted.

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
