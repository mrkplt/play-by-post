# Sorbet Type Compliance Plan

## Core Principle

**Don't promote a file to `# typed: true` until you can type it properly without `T.untyped`.**

Leave a file at `# typed: false` rather than adding `T.untyped` placeholders. A honest `false` sigil is better than a `true` sigil with `T.untyped` scattered through it.

Type a file only when its dependencies are already typed. If `scene.rb` depends on `game_member.rb`, type `game_member.rb` first. Doing it out of order forces `T.untyped` at the seams.

---

## Phase 1: Add Sigils to Base Classes

Add `# typed: true` to base classes (no sigs yet — Sorbet only checks explicit `sig` blocks at this level). If `srb tc` surfaces violations when adding the sigil, fix the violation rather than suppressing it with `T.untyped`.

Files:
- `app/controllers/application_controller.rb`
- `app/models/application_record.rb`
- `app/jobs/application_job.rb`
- `app/mailers/application_mailer.rb`
- `app/mailboxes/application_mailbox.rb`

Run `bundle exec srb tc` after each file to surface violations early.

---

## Phase 2: Type the Remaining Models

Before typing any model, regenerate Tapioca DSL RBIs to get proper types for Rails DSL (associations, scopes, enums, validations) without reaching for `T.untyped`:

```bash
bundle exec tapioca dsl
```

This gives proper types for:
- `has_many` → `ActiveRecord::Associations::CollectionProxy[GameMember]`
- `belongs_to` → the associated model type
- `enum` → typed predicate methods
- `scope` → typed chainable queries

If a specific Rails method is still unresolved, add a targeted shim to `sorbet/rbi/shims/` rather than silencing the call site.

Order by dependency depth (type simpler models first):

1. `scene_participant.rb`, `notification_preference.rb`, `user_profile.rb` — simple join/value models
2. `game_member.rb`, `invitation.rb`, `character_version.rb` — mid-tier
3. `character.rb`, `scene.rb` — high-usage, many associations
4. `current.rb`, `user.rb` — Devise-heavy, extend shims as needed

---

## Phase 3: Add Sigs to Typed-But-Unsigned Controllers

Controllers already have `# typed: true` but zero `sig` blocks — they are the largest regression risk. Use `T.must` instead of `T.untyped` when asserting non-nil after a find:

```ruby
sig { void }
def set_game
  @game = T.must(Game.find(params[:id]))
end
```

`T.must` raises at runtime if the assertion fails — it is honest about the contract rather than hiding it.

Order:
1. `games_controller.rb`, `scenes_controller.rb`, `posts_controller.rb`
2. `characters_controller.rb`, `game_files_controller.rb`
3. `invitations_controller.rb`, `profiles_controller.rb`, `users/sessions_controller.rb`

---

## Phase 4: Type the Async Layer

Add `# typed: true` + sigs to jobs, mailers, and mailboxes. By this phase the domain models are typed, so call sites have real types to reference.

Files:
- `app/jobs/post_digest_job.rb`
- `app/mailers/notification_mailer.rb`
- `app/mailers/invitation_mailer.rb`
- `app/mailboxes/scene_mailbox.rb`
- `app/services/email_content_extractor.rb`

Type `perform` and delivery method signatures explicitly.

---

## Phase 5: Define Port Interfaces

Create `app/ports/` with Sorbet interface modules — one per external seam. Every parameter must have a real type. If a method takes something that cannot be typed yet, the interface boundary is in the wrong place.

Example:

```ruby
# app/ports/notifier.rb
# typed: strict
module Ports
  module Notifier
    extend T::Helpers
    interface!

    sig { abstract.params(scene: Scene, recipient: User).void }
    def notify_new_scene(scene:, recipient:); end

    sig { abstract.params(scene: Scene, user: User, posts: T::Array[Post]).void }
    def notify_post_digest(scene:, user:, posts:); end
  end
end
```

Ports to define:
- `Ports::Notifier` — wraps `NotificationMailer`
- `Ports::InvitationSender` — wraps `InvitationMailer`
- `Ports::FileStore` — wraps Active Storage attachment logic

---

## Phase 6: Create Adapter Wrappers

Thin wrappers around concrete mailers/storage that `include` the port module. Sorbet enforces that the adapter fully implements the port — missing or mistyped methods become type errors.

```ruby
# app/adapters/mailer_notifier.rb
# typed: strict
class MailerNotifier
  include Ports::Notifier

  sig { override.params(scene: Scene, recipient: User).void }
  def notify_new_scene(scene:, recipient:)
    NotificationMailer.new_scene(scene, recipient).deliver_later
  end
end
```

---

## Phase 7: Inject Ports into Consumers, Type Against the Interface

Extract direct mailer/job calls out of controllers and inject the adapter. The `T.let` with the interface type is the key step — Sorbet enforces that anything assigned to the variable satisfies the port interface, not just that it happens to be a concrete class.

```ruby
class ScenesController < ApplicationController
  def initialize(notifier: MailerNotifier.new)
    @notifier = T.let(notifier, Ports::Notifier)
    super()
  end
end
```

Phases 5–7 should ship as a single PR per port since the interface, adapter, and consumer change together.

---

## Phase 8: Raise Sigil Levels Selectively (ongoing)

Once a file has complete sig coverage and `srb tc` passes cleanly, raise it to `# typed: strict`. Strict requires sigs on all methods — Sorbet will report what is missing.

- Start with services and presenters (already well-typed)
- Controllers and models can stay at `true` longer
- Update `bin/quality-metrics` baseline as each file is raised

### Checkpoint before promoting any file

```bash
bundle exec srb tc 2>&1 | grep "path/to/file.rb"
```

If the only way to clear errors is `T.untyped`, the file is not ready.

---

## Handling Legitimate Gaps

Two cases where `T.untyped` is genuinely unavoidable:

1. **Third-party gem with no RBI** — add a shim in `sorbet/rbi/shims/`. Check `sorbet/rbi/gems/` first; Tapioca may already have it.

2. **Active Storage variants/previews** — use a specific union rather than `T.untyped`:
   ```ruby
   sig { returns(T.nilable(T.any(ActiveStorage::VariantWithRecord, ActiveStorage::Preview))) }
   ```

In all other cases: leave the file at `# typed: false` and note it as a known gap rather than papering over it.

---

## Current State (as of audit)

| Category    | Files | With Sigs | With Sigil | Coverage |
|-------------|-------|-----------|------------|----------|
| Components  | 10    | 9 (90%)   | 10         | 100%     |
| Presenters  | 5     | 5 (100%)  | 5          | 100%     |
| Controllers | 9     | 0 (0%)    | 8          | 89%      |
| Models      | 15    | 4 (26%)   | 5          | 33%      |
| Services    | 2     | 1 (50%)   | 1          | 50%      |
| Jobs        | 2     | 0         | 0          | 0%       |
| Mailers     | 3     | 0         | 0          | 0%       |
| Mailboxes   | 2     | 0         | 0          | 0%       |
| **Total**   | **53**| **19 (36%)** | **30 (57%)** | **57%** |
