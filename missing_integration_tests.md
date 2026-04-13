# Missing Integration Tests

Features defined in `context/REQUIREMENTS.md` that have **no system-level test coverage**.
Each section describes what needs to be tested, the relevant code entry points, and any
known constraints.

---

## 1. Game Export

**Requirements:** `context/REQUIREMENTS.md` — "Game Export" section

**What needs testing:**
- Any non-banned member can request a zip export from the game view
- Removed members only export scenes they participated in; active members/GMs get all scenes
- Banned members cannot export (button absent / request rejected)
- "Export All Games" on the profile page bundles all non-banned games
- Rate limit: one export request per user per game per 24-hour window (button disabled after request)
- "Export All Games" has its own independent 24-hour rate limit
- Export delivery: `ExportMailer#export_ready` email is sent with a signed download link
- Export failure: `ExportMailer#export_failed` is sent if the job fails

**Code entry points:**
- `app/controllers/game_exports_controller.rb` — `POST /games/:id/export`
- `app/controllers/profiles_controller.rb` — `POST /profile/export_all`
- `app/jobs/export_job.rb`
- `app/services/game_export_service.rb`
- `app/mailers/export_mailer.rb`
- `app/models/game_export_request.rb` — `rate_limited?` class method

**Constraints:**
- `ExportJob` uses Solid Queue. Set `queue_adapter = :test` and call `perform_now` in specs.
- The signed Active Storage URL can be stubbed; the archive contents are tested in unit/service specs.

---

## 2. Email Notifications

**Requirements:** `context/REQUIREMENTS.md` — "Notifications & Email" section

### 2a. New Scene Email

- Sent to all participants when a scene is created (except the creator)
- Confirmed non-creator participants receive the email; creator does not

**Code:** `app/mailers/notification_mailer.rb` — `new_scene` action (or equivalent)

### 2b. Post Digest Email

- Sent to participants who haven't visited a scene in 24+ hours, for posts since their last visit
- Not sent if the participant authored all recent posts (nothing new from others)
- Digest is suppressed if the participant has muted notifications for the scene

**Code:** `app/jobs/post_digest_job.rb`, `app/mailers/notification_mailer.rb#post_digest`

Note: `scenes_spec.rb` already has a test that muting suppresses the digest job. What's missing:
- A test that the digest IS sent when there is activity since last visit
- A test that it is NOT sent when the only new posts are from the digest recipient themselves

### 2c. Scene Resolution Email

- Sent to all participants when GM resolves a scene
- Includes the outcomes text entered by the GM

**Code:** `app/mailers/notification_mailer.rb` — resolution action, called from `scenes_controller.rb#resolve` (or equivalent)

### 2d. Magic Link Login Email

- Sent when a user submits the sign-in form
- Confirmed by `sign_in_spec.rb` implicitly (it extracts the URL), but no test verifies the
  email subject, recipient, or content

---

## 3. Reply-by-Email

**Requirements:** `context/REQUIREMENTS.md` — "Reply-by-Email" section

**What needs testing:**
- Replying to a notification email creates a post in the correct scene
- The sender must be a current scene participant; invalid senders are rejected (no post created)
- Email content is cleaned (quoted text, signatures stripped) before posting
- Created posts are always in-character (OOC cannot be set via email)
- If content cleaning fails after retries, the post is created from the raw email body and
  the sender is notified via email

**Code entry points:**
- `app/mailboxes/scene_mailbox.rb`
- `app/services/email_content_extractor.rb`
- ActionMailbox routing in `app/mailboxes/application_mailbox.rb`

**How to test with ActionMailbox:**
```ruby
receive_inbound_email_from_mail(
  to: "reply+scene_42@inbound.example.com",
  from: "player@example.com",
  subject: "Re: The Bridge",
  body: "I step through the door.\n\n> Original post...\n-- \nSignature"
)
```
Use `ActionMailbox::TestHelper` (`include ActionMailbox::TestHelper` in the spec).

---

## 4. Dashboard New Activity Indicator

**Requirements:** `context/REQUIREMENTS.md` — "Player Dashboard" section

> "a 'new activity' indicator if anything changed since last login"

**Status:** The `@dashboard_items` hash in `GamesController#index` does not currently include
a new-activity flag, and the `app/views/games/index.html.erb` template does not render one.
This requirement appears **unimplemented**. A test cannot be written until the feature exists.

**What to implement first:**
1. Add `new_activity: (last_post_at > current_user.last_login_at)` (or similar) to each
   dashboard item in `GamesController#index`
2. Render a visual indicator in `app/views/games/index.html.erb`
3. Write a system test verifying the indicator appears when there is activity since last login
   and is absent when there is none

---

## 5. Dashboard "+N" Additional Characters

**Requirements:** `context/REQUIREMENTS.md` — "Player Dashboard" section

> "Players with multiple characters see their primary character name with a '+N' count for additional characters"

**Status:** The `@dashboard_items` hash includes `primary_character` but not a count of
additional characters, and the template does not render a "+N" indicator.
This requirement appears **unimplemented**.

**What to implement first:**
1. Add `additional_character_count: game.characters.active.where(user: current_user).count - 1`
   (clamped to 0) to the dashboard item
2. Render "+ N more" in the template when `additional_character_count > 0`
3. Write a system test verifying the count is shown with multiple characters and absent with one

---

## Notes

- All system specs live in `spec/system/` and use the Playwright driver (`type: :feature`)
- Auth helper: `sign_in_as(user)` (see `spec/support/sign_in_helper.rb`)
- Email assertions: `ActionMailer::Base.deliveries` is cleared between examples by DatabaseCleaner;
  use `expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include("...")`
- Job testing: set `ActiveJob::Base.queue_adapter = :test` and call `JobClass.perform_now`
