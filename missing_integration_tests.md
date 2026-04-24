# Missing Integration Tests

Features defined in `context/REQUIREMENTS.md` that have **no system-level test coverage**.
Each section describes what needs to be tested, the relevant code entry points, and any
known constraints.

---

## 1. Dashboard New Activity Indicator

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

## 2. Dashboard "+N" Additional Characters

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
