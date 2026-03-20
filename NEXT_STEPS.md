# Next Steps

## 1. Get it running locally

```bash
bin/rails server
```

Visit http://localhost:3000. You'll hit the login page. Since Devise passwordless sends
a real email, configure letter_opener for local dev so magic links open in the browser
instead of going to Mailgun:

```ruby
# Gemfile (development group)
gem "letter_opener"
```

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

## 2. Git + GitHub

```bash
git init
git add .
git commit -m "Initial Rails app"
gh repo create play-by-post --private --source=. --push
```

## 3. Deploy to Railway

1. Create a new Railway project at railway.app
2. Add a **PostgreSQL** service — Railway injects `DATABASE_URL` automatically
3. Connect your GitHub repo to a **Web** service
4. Set environment variables (see `.env.example`):
   - `SECRET_KEY_BASE` — run `bin/rails secret` to generate
   - `RAILS_ENV=production`
   - `APP_HOST` — your Railway app URL (e.g. `play-by-post.up.railway.app`)
5. Railway will detect `railway.toml` and run `db:migrate` on deploy automatically

## 4. Mailgun

1. Sign up at mailgun.com (free tier: 100 emails/day)
2. Add and verify your domain (or use the Mailgun sandbox for testing)
3. Set `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` in Railway env vars
4. For inbound email (email-to-post):
   - Add a Mailgun inbound route forwarding `scene-*@inbound.yourdomain.com` to
     `https://your-app.up.railway.app/rails/action_mailbox/mailgun/inbound_emails/mime`
   - Set `RAILS_INBOUND_EMAIL_PASSWORD` — a secret you choose, set in both Mailgun
     and Railway env vars (used to authenticate the webhook)

## 5. Cloudflare R2 (file storage)

Skip this initially — the app uses local disk storage in development and you can
defer R2 until you need file uploads in production.

When ready:
1. Create a Cloudflare account → R2 → New bucket
2. Create an API token with R2 read/write permissions
3. Set `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_ENDPOINT`
   in Railway env vars

## 6. OpenRouter (inbound email LLM parsing)

Sign up at openrouter.ai — the `google/gemma-3-4b-it:free` model used for stripping
email artifacts is free. Set `OPENROUTER_API_KEY` in Railway env vars.

The app degrades gracefully if the key is missing — it uses the raw email body.

## 7. Untested features needing implementation + specs

### a. `sheets_hidden` game flag

The `games.sheets_hidden` column exists in the schema and the factory sets it to `false`, but
nothing reads it. The `Character.visible_to` scope currently ignores it entirely.

**What needs to be built:**

1. Update `Character.visible_to` to respect the flag:
   ```ruby
   scope :visible_to, ->(viewer, game) {
     return all if game.game_master?(viewer)
     return where(user: viewer) if game.sheets_hidden?
     where(hidden: false).or(where(user: viewer))
   }
   ```

2. Add a GM toggle on the game view or player management page:
   ```erb
   <%= button_to game.sheets_hidden? ? "Show sheets" : "Hide all sheets",
       toggle_sheets_hidden_game_path(game), method: :patch, class: "btn btn--secondary" %>
   ```

3. Add the route and controller action in `GamesController`:
   ```ruby
   patch :toggle_sheets_hidden, on: :member
   # controller:
   def toggle_sheets_hidden
     @game.update!(sheets_hidden: !@game.sheets_hidden?)
     redirect_to game_path(@game)
   end
   ```

**Spec to add** in `spec/system/characters_spec.rb`:
```ruby
it "sheets_hidden hides all sheets from non-GM players" do
  create(:character, game: game, user: player, name: "Thornwall")
  game.update!(sheets_hidden: true)
  other_player = create(:user, :with_profile)
  create(:game_member, game: game, user: other_player)

  sign_in_as(other_player)
  visit game_path(game)

  expect(page).not_to have_text("Thornwall")
end

it "sheets_hidden still shows own character to the player" do
  create(:character, game: game, user: player, name: "Thornwall")
  game.update!(sheets_hidden: true)

  sign_in_as(player)
  visit game_path(game)

  expect(page).to have_text("Thornwall")
end
```

---

### b. Scene toolbar hidden after resolution

The toolbar (Quick Scene, New Scene, Edit Participants, Mute, End Scene buttons) is already
wrapped in `<% if !@scene.resolved? %>` in `app/views/scenes/show.html.erb`, so the
behaviour is implemented. There is no test for it.

**Spec to add** in `spec/system/scenes_spec.rb` within the `scene resolution` describe block:
```ruby
it "hides the scene toolbar after resolution" do
  scene.update!(resolved_at: Time.current, resolution: "Done.")
  visit game_scene_path(game, scene)

  expect(page).not_to have_button("End Scene")
  expect(page).not_to have_link("Quick Scene")
  expect(page).not_to have_link("New Scene")
end
```

---

### c. `PostDigestJob` email delivery

The job exists at `app/jobs/post_digest_job.rb`. It finds scenes with recent posts,
checks each participant's `last_visited_at`, skips muted preferences, and sends a digest
via `NotificationMailer.post_digest`.

**What still needs to be wired up:**

- A cron schedule. The job is not scheduled anywhere. Add a Sidekiq-cron entry in
  `config/recurring.yml` (Rails 8 solid queue) or configure via `sidekiq-cron` gem:
  ```yaml
  # config/recurring.yml  (Sidekiq-cron format)
  post_digest:
    cron: "0 8 * * *"   # 8am UTC daily
    class: PostDigestJob
  ```

**Spec to add** in a new `spec/jobs/post_digest_job_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe PostDigestJob do
  let(:gm)     { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game)   { create(:game) }
  let(:scene)  { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm,    last_visited_at: 2.days.ago)
    create(:scene_participant, scene: scene, user: player, last_visited_at: 2.days.ago)
    create(:post, scene: scene, user: gm, created_at: 1.hour.ago)
  end

  it "sends a digest to participants who haven't visited in 24 hours" do
    expect { described_class.new.perform }
      .to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.to).to include(player.email)
  end

  it "does not send to muted participants" do
    NotificationPreference.create!(scene: scene, user: player, muted: true)

    expect { described_class.new.perform }
      .not_to change { ActionMailer::Base.deliveries.size }
  end

  it "does not send to participants who visited recently" do
    scene.scene_participants.find_by(user: player).update!(last_visited_at: 30.minutes.ago)

    expect { described_class.new.perform }
      .not_to change { ActionMailer::Base.deliveries.size }
  end
end
```

---

### d. Inbound email / scene mailbox routing

The mailbox exists at `app/mailboxes/scene_mailbox.rb`. It routes on `scene-{id}@inbound.*`,
validates the sender is a scene participant, calls `EmailContentExtractor` (which uses
OpenRouter to strip quoted replies), and creates a post.

**What still needs to be wired up:**

- ActionMailbox routing in `app/mailboxes/application_mailbox.rb` — verify it has:
  ```ruby
  routing(/\Ascene-\d+@/i => :scene)
  ```
- Mailgun inbound webhook configured (see section 4 above).
- `RAILS_INBOUND_EMAIL_PASSWORD` set in Railway env vars.

**Spec to add** in a new `spec/mailboxes/scene_mailbox_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe SceneMailbox, type: :mailbox do
  let(:gm)     { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game)   { create(:game) }
  let(:scene)  { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  it "creates a post from an inbound email by a participant" do
    expect {
      receive_inbound_email_from_mail(
        from: player.email,
        to: "scene-#{scene.id}@inbound.example.com",
        subject: "Re: scene update",
        body: "I head into the tavern."
      )
    }.to change { scene.posts.count }.by(1)

    expect(scene.posts.last.content).to eq("I head into the tavern.")
    expect(scene.posts.last.user).to eq(player)
  end

  it "bounces email from a non-participant" do
    outsider = create(:user, :with_profile)
    mail = receive_inbound_email_from_mail(
      from: outsider.email,
      to: "scene-#{scene.id}@inbound.example.com",
      body: "Can I join?"
    )

    expect(mail).to have_been_bounced
  end

  it "bounces email to an unknown scene" do
    mail = receive_inbound_email_from_mail(
      from: player.email,
      to: "scene-99999@inbound.example.com",
      body: "Hello?"
    )

    expect(mail).to have_been_bounced
  end
end
```

Note: `EmailContentExtractor` will fall back to the raw body when `openrouter_api_key`
is blank (which it is in test), so no mocking needed for basic routing tests.

---

## 9. New features not yet built

### a. Add a player to an existing scene

Currently there is no way for a GM to add a player to a scene after it has been created,
other than through the "Edit Participants" link — which is only visible to users who are
already participants. A GM viewing a scene they created but didn't add themselves to cannot
reach the participant editor.

More importantly, there is no self-service flow for a player to request joining a scene,
or for the GM to add someone directly from the game view without entering the scene first.

**What needs to be built:**

1. **Make "Edit Participants" always visible to the GM** regardless of whether they are a
   participant. Change the toolbar guard in `app/views/scenes/show.html.erb`:
   ```erb
   <%# was: if @is_participant || @is_gm %>
   <% if @is_gm %>
     <%= link_to "Edit Participants", edit_game_scene_participants_path(@game, @scene), class: "btn btn--secondary" %>
   <% end %>
   ```

2. **Add a "Join Scene" button for non-participant active members.** When a player is an
   active game member but not a scene participant, show a join button (for non-private
   scenes, or private scenes the GM has made visible):
   ```erb
   <% if !@is_participant && !@is_gm && @game.member_for(current_user)&.active? && !@scene.private? %>
     <%= button_to "Join Scene", game_scene_participants_path(@game, @scene),
         method: :post, class: "btn btn--secondary",
         params: { participant_ids: [@scene.scene_participants.pluck(:user_id) + [current_user.id]] } %>
   <% end %>
   ```
   Or add a dedicated `join` action on `SceneParticipantsController`:
   ```ruby
   # routes.rb — inside scenes resources:
   resource :participants, only: %i[edit update], controller: "scene_participants" do
     post :join, on: :collection
   end

   # scene_participants_controller.rb:
   def join
     return if @scene.private? && !@game.game_master?(current_user)
     @scene.scene_participants.find_or_create_by!(user: current_user)
     redirect_to game_scene_path(@game, @scene), notice: "You have joined this scene."
   end
   ```

3. **Show an "Add to scene" affordance on scene cards in the game view** (GM only) — a
   small button or dropdown on each scene card letting the GM add any active player who
   isn't already a participant.

**Specs to add** in `spec/system/scenes_spec.rb`:
```ruby
it "GM can add a player to an existing scene via Edit Participants" do
  scene = create(:scene, game: game)
  create(:scene_participant, scene: scene, user: gm)
  sign_in_as(gm)
  visit game_scene_path(game, scene)

  click_on "Edit Participants"
  check player.display_name
  click_on "Update Participants"

  expect(page).to have_text(player.display_name)
end

it "player can join a non-private scene they are not yet in" do
  scene = create(:scene, game: game)
  create(:scene_participant, scene: scene, user: gm)
  sign_in_as(player)
  visit game_scene_path(game, scene)

  click_on "Join Scene"

  expect(page).to have_css("#post_composer")
end
```

---

## 10. Former player behavior needs clarification and enforcement

The `removed` and `banned` statuses exist on `game_members` but their access rules are
inconsistently applied and the "Former" player experience is not fully implemented.

### Current behavior (as of now)

- **Banned**: hidden from dashboard (`where.not(status: "banned")`), blocked from game/scene access
- **Removed**: hidden from dashboard (same query — removed players also disappear), but controllers
  allow full access (`return if membership&.active? || membership&.removed?`) — identical to active

### What was intended (per original plan)

- **Removed**: read-only access to the game — can see scenes and posts but cannot post,
  create characters, or edit anything. Appears in dashboard with a "Former" badge.
- **Banned**: no access at all. Blocked everywhere. Does not appear on dashboard.

### What needs to be decided

1. **Should removed players see the game on their dashboard?** Currently they don't (the
   `where.not(status: "banned")` query drops them). The plan says they should, with a "Former" badge.

2. **Should removed players have read-only access?** If yes, the controllers need to distinguish
   between removed (read) and active (read+write). Currently removed players can post, edit
   characters, etc.

### What needs to be built

1. **Dashboard**: change `where.not(status: "banned")` to include removed members, add "Former" badge:
   ```ruby
   # games_controller.rb
   @memberships = current_user.game_members
     .where.not(status: "banned")  # already correct — just confirm removed shows up
   ```
   ```erb
   <%# games/index.html.erb — in the game card %>
   <% if membership.removed? %>
     <span class="badge badge--gray">Former</span>
   <% end %>
   ```

2. **Read-only enforcement for removed players**: add a `require_active_member!` before_action
   on any write action (create post, create character, edit participants, etc.):
   ```ruby
   def require_active_member!
     membership = @game.member_for(current_user)
     return if membership&.game_master? || membership&.active?
     redirect_to game_path(@game), alert: "You no longer have posting access to this game."
   end
   ```

3. **Composer guard**: already partially in place — `@game.member_for(current_user)&.active?`
   hides the composer for non-active members. Verify this covers removed players correctly.

### Specs to add

```ruby
it "removed player sees game on dashboard with Former badge" do
  membership.update!(status: "removed")
  sign_in_as(player)
  visit root_path
  expect(page).to have_text(game.name)
  expect(page).to have_text("Former")
end

it "removed player cannot post in a scene" do
  membership.update!(status: "removed")
  sign_in_as(player)
  visit game_scene_path(game, scene)
  expect(page).not_to have_css("#post_composer")
end

it "banned player does not see game on dashboard" do
  membership.update!(status: "banned")
  sign_in_as(player)
  visit root_path
  expect(page).not_to have_text(game.name)
end

it "banned player cannot access the game directly" do
  membership.update!(status: "banned")
  sign_in_as(player)
  visit game_path(game)
  expect(page).to have_current_path(root_path)
end
```

---

## 11. Player profile page (`profiles#show`)

There is no public profile page. The profile resource only has `edit` and `update` —
clicking your name in the navbar takes you straight to the edit form.

**What to build:**

A `profiles#show` page, accessible at `/profile`, showing:
- Display name
- Games the user is a member of (with role)
- Any other preferences worth surfacing (e.g. hide OOC setting)

The navbar link should go to `profile_path` (show) with an "Edit" button on that page,
rather than dropping the user directly into the form.

**Routes:**
```ruby
resource :profile, only: %i[show edit update], controller: "profiles" do
  post :toggle_hide_ooc, on: :collection
end
```

**Controller:**
```ruby
def show
  @profile = current_user.user_profile
end
```

**Navbar change** (`layouts/_navbar.html.erb`):
```erb
<%# Change edit_profile_path → profile_path %>
<%= link_to current_user.display_name || current_user.email.split("@").first, profile_path %>
```

---

## 13. Things not yet built

- **Image attachments on posts and scenes** — the models have `has_one_attached :image`
  but the composer form doesn't include a file upload field yet. Add it to
  `_composer.html.erb` and render thumbnails in `_post_item.html.erb`.

- **`aws-sdk-s3` gem** — Active Storage with R2 requires the S3 adapter gem.
  Add `gem "aws-sdk-s3", require: false` to the Gemfile before enabling R2.

## 14. Recommended first thing to test end-to-end

1. Start the server locally
2. Go to `/users/sign_in`, enter your email
3. Open the letter_opener browser tab, click the magic link
4. Set your display name
5. Create a game
6. Create a scene
7. Post in the scene
8. Verify the edit link appears and disappears after 10 minutes
