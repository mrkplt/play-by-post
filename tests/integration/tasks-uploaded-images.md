# Task Checklist: Uploadable Images — Character Portraits & User Avatars

Plan: `tests/integration/uploaded-images.md`
Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/102
Branch: `102-character-portraits-uploaded-images` · PR #249

Execution: sequential (single repo, shared files — routes/User/Character/importmap/.mutant.yml).
Each task: implemented → tested → linted → committed → pushed → box checked.

## A. Remove Post/Scene inline images  ✅ committed c6b364c
- [x] A1. Strip `:image` attachment + validations + `display_image` from `Post` and `Scene` (incl. `images_allowed_for_game`).
- [x] A2. Delete `ImageAttachable` concern; remove its use in Posts/Scenes controllers. (Also dropped dead scene_image/post_image KEY_PREFIXES from AttachmentUploader.)
- [x] A3. Remove image fields from `post_composer_component` + `scene_form_component` (+ dropped now-unneeded `multipart: true`).
- [x] A4. Remove image display: `scenes/show`, `post_item_component`, `post_presenter`, `scene_navigation_presenter`. **DEVIATION:** did NOT delete `lightbox_controller.js` — it belongs to the GameFile media gallery (kept), not post/scene images (which used plain `image_tag`). Plan misattributed it.
- [x] A5. Remove `images_disabled` setting: `GameSettingToggle` entry, route, settings action, `ImagesToggleComponent`, presenter method, edit-game row.
- [x] A6. Migration: drop `images_disabled` column from games.
- [x] A7. Delete/adjust affected specs (post/scene image, images_toggle, image_attachments system spec). Full non-system suite green (3177 examples). Fast tier green on push.

## B. UploadedImage subsystem
- [x] B1. `UploadedImage::Model` module (commit 820a962): attachment (adopter-declared), IMAGE_TYPES/MAX_SIZE, `acceptable_image`, display(512)+thumbnail(96) square variants, `make_current!`, abstract owner/siblings.
- [x] B2. `CharacterImage` + `UserImage` models; migrations (commit 820a962).
- [x] B3. `Character` (current_portrait/portrait_variant) + `User` (current_avatar/avatar_variant) (commit 820a962). Plus game-purge wiring for character images.
- [x] B4. `ImageLibrary` controller module + `CharacterImagesController` + `UserImagesController` + routes (commit b15006e).
- [x] B5. `CharacterImagePolicy` + `UserImagePolicy` (commit b15006e). **DECISION:** CharacterImage#manage? = **owning player ONLY** (GM excluded), per owner — deliberately narrower than Character#editable_by?. Declared in config/policy_invariants.yml.
- [x] B6. `Shared::ImageLibraryComponent` + `Shared::ImageCropperComponent`; registered in `.mutant.yml` (commit c78ea42).
- [x] B7. Presenters (ImageLibraryPresenter + character/user subclasses) supplying Item data (commit c78ea42).
- [x] B8. `image_cropper_controller.js` Stimulus + pinned `cropperjs@1.6.2` via importmap + `importmap audit` clean (commit c78ea42). **DECISION:** pinned v1 (imperative API, single vendored file) over v2 (web-components, sprawling deps).
- [x] B9. Portrait section on `characters/show`; avatar section on profile (commit c78ea42).

## C. Tests & gates
- [x] C1. Model specs via shared example group (both image models) (commit 820a962).
- [x] C2. Request specs per controller (upload, set-current, destroy, authz denials) (commit b15006e).
- [x] C3. Component specs (all states) for both new components (commit c78ea42).
- [x] C4. Policy specs (capability + role) (commit b15006e).
- [x] C5. Feature specs (character_portraits + user_avatars): render, set-current, delete, owner-only gating, and a full cropper upload on BOTH viewports (commit f42c51e). Caught + fixed a real trigger-scope bug.
- [x] C6. Sorbet clean ✅; rspec green ✅ (system flakiness = pre-existing SQLite locks, verified vs master). Mutation: every new subject at its practical ceiling — policies 100%, both library presenters 100%, components 96%, UploadedImage::Model 95%, ImageLibrary 95%, concrete controllers 94%, concrete models 93%, abstract base 88%. Aggregate mutation jumped 61% → **93.18%** (well above the 80% floor); remaining alive = equivalent + abstract-stub mutants. Also fixed a dedup-ceiling regression (extracted repeated component class strings). Final `quality-metrics --check` running.
- [x] C7. Gem-maintenance: `bundle outdated` = 3 (diff-lcs, rubocop-performance, rubocop-rails), all transitive/below the >5 threshold → no forced update per repo rule. Cropperjs@1.6.2 pinned; importmap audit clean.

## Completion tail
- [x] Independent evaluation agent (fresh, non-implementer): **PASS** — full plan conformance, zero dangling refs, both deviations justified. Two doc-only nits (fixed in 1d337bc).
- [x] Code review agent over this run's commits: 1 MEDIUM (fixed), 2 LOW (1 fixed, 1 noted). See Decisions.
- [x] Decision log appended below.
- [~] `bin/full-check`: quality gate + Brakeman(0) + srb + non-system specs all green. System specs hit pre-existing SQLite "database is locked" flakiness (verified: same specs pass on master AND branch when not under full-suite lock pressure — not our defect). Mutation gate running separately.
- [ ] finish_work (PR ready, cross-links).

## Decisions

Design decisions (from conversation with the owner):
- **Two owners, one abstraction.** CharacterImage + UserImage each include a shared plain
  module `UploadedImage::Model` (not an ActiveSupport::Concern — bin/check-concerns). Separate
  per-owner libraries, not a shared/polymorphic one.
- **Crop-on-upload only**, square; "current" is a boolean flag (no copied blob).
- **Character portraits: owning player ONLY** — the GM is deliberately excluded (narrower than
  Character#editable_by?). User avatars: owner only. Declared in config/policy_invariants.yml.
- **Cropper.js v1.6.2** (imperative API, single vendored file) chosen over v2 (web-components,
  sprawling deps); ported from hex-flower-app/TileCreator.jsx.

Deviations from the plan:
- **lightbox_controller.js NOT deleted.** The plan listed it under Post/Scene removal, but it
  belongs to the GameFile media gallery (kept); post/scene images used a plain image_tag. A
  10-second grep confirmed the misattribution before deleting.

Evaluator findings & disposition:
- PASS overall. Nit 1 (stale "or the GM" comment) → fixed (1d337bc). Nit 2 (portrait-specific
  copy on avatar path) → fixed (neutral "Image added/updated", "image.jpg") (1d337bc).

Code-review findings & disposition:
- **#1 MEDIUM — orphaned R2 blob on rejected upload.** build_uploaded_image uploaded to R2
  before save/validation, so an oversized/non-image upload from a direct API caller leaked a
  bucket object. **FIXED** (1d337bc): validate size + content-type in the controller before
  AttachmentUploader.attach; request specs assert AttachmentUploader is never called on
  rejection.
- **#2 LOW — content-type trusts client MIME.** Mitigated in practice (blob only ever served
  through a re-encoded resize_to_fill JPEG variant, so non-image bytes fail at variant time, no
  XSS). **NOTED, not changed** — magic-byte sniffing is defense-in-depth beyond this card; the
  same shape pre-exists for GameFile.
- **#3 LOW — canvas.toBlob can yield null.** **FIXED** (1d337bc): guard shows a clear error
  instead of POSTing an empty part.
- Reviewer explicitly verified (and I concur): authorization scoping (cross-owner id →
  RecordNotFound → redirect), make_current! exclusivity (SQLite-serialized), game-purge blob
  cleanup, CSRF, N+1 eager-loading, .mutant.yml + policy_invariants coverage — all correct.

Test-flakiness investigation:
- 34 system-spec failures in bin/full-check were all `SQLite3::BusyException: database is
  locked`, on specs unrelated to this change (scenes/sign_in/unread_aura/tablet/summary). Ran
  the sign_in + unread_aura + tablet trio on a clean origin/master worktree: 12/12 pass. Ran the
  same trio on this branch: 12/12 pass. The failures are full-suite lock contention, pre-existing
  and environmental — not introduced here. Our own portrait/avatar system specs passed.
