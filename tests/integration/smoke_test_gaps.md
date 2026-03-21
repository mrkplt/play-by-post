# Smoke Test Gap Coverage

## Context

The end-to-end smoke test checklist (NEXT_STEPS.md item 12) has 15 items.
13 are fully covered by existing system specs. Two gaps remain.

## Gap 1: GM uploads a file via the form (item 13)

**Current state:** `game_files_spec.rb` tests file visibility and access control
but creates files programmatically (`gf.file.attach(...)`) rather than testing
the upload form.

**Test plan:**
- Sign in as GM
- Visit the game files page
- Attach a file via the upload form (`attach_file`)
- Submit the form
- Verify the file appears in the file list with filename, type, and size
- Verify the "File uploaded." flash message

**File:** `spec/system/game_files_spec.rb` (add to existing)

## Gap 2: Mute toggle persists and suppresses digest (item 12)

**Current state:** `scenes_spec.rb` tests the mute/unmute UI toggle.
`post_digest_job_spec.rb` tests that muted participants don't get digests.
No test connects the two: muting via UI → digest skipped.

**Test plan:**
- Sign in as GM (who is a scene participant)
- Mute notifications via the scene actions menu
- Verify the mute persists in the database (`NotificationPreference.muted?`)
- Run `PostDigestJob` and verify no digest is enqueued for the muted user

**File:** `spec/system/scenes_spec.rb` (add to existing notification mute describe block)
