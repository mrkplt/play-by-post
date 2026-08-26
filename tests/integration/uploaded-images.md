# Plan: Uploadable Images — Character Portraits & User Avatars

Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/102

## Goal

Add a per-owner **image library** with in-browser crop/scale-on-upload, persisted to
R2 via Active Storage. Two owners — **Character** (portrait) and **User** (avatar) — each
get their own *separate* library, sharing one concern, one set of components/views, and
one Stimulus cropper. Selecting a "current" image is a flag on the library row.

As part of the same change: **strip inline `:image` uploads off Post and Scene** (a
different treatment is coming for those) and remove the now-orphaned `images_disabled`
game setting.

## Locked decisions

- Concrete models `CharacterImage` / `UserImage`, each `include UploadedImage::Model`
  (a plain module per repo convention — not an ActiveSupport::Concern). Not polymorphic.
- Crop-on-upload only; the stored blob is already cropped (square).
- "Current" = a boolean flag on the library row; owner's portrait/avatar = its current row.
  No copied attachment.
- Portraits are NOT part of Character version history (separate table ⇒ no `save` snapshot).
- Cropper is portrait/avatar-only for now. Post/Scene get no cropper (they lose images).
- `GameFile` media gallery is a DIFFERENT feature — untouched.
- `AttachmentUploader` is shared (game_files, export) — kept; only its post/scene callers go.

## Tasks

### A. Remove Post/Scene inline images
- [ ] Remove `has_one_attached :image`, `IMAGE_TYPES`, `IMAGE_MAX_SIZE`, `acceptable_image`,
      `display_image` from `Post` and `Scene`; remove `images_allowed_for_game`.
- [ ] Delete `ImageAttachable` controller concern; drop its use in Posts/Scenes controllers.
- [ ] Remove image file fields from `post_composer_component` and `scene_form_component`.
- [ ] Remove image display from `scenes/show`, `post_item_component`, `post_presenter`,
      `scene_navigation_presenter`, and delete `lightbox_controller.js`.
- [ ] Remove `images_disabled` setting: `GameSettingToggle` entry, `toggle_images_disabled`
      route + settings controller action, `ImagesToggleComponent`, `images_disabled?`
      presenter method, edit-game view row.
- [ ] Migration to drop `images_disabled` column from games.
- [ ] Delete/adjust the affected specs (post/scene image, images_toggle, lightbox,
      image_attachments system spec, etc.).

### B. UploadedImage subsystem
- [ ] `UploadedImage::Model` module: `has_one_attached :file`, shared IMAGE_TYPES/MAX_SIZE,
      `acceptable_image` validation, SEVERAL named variants (large display + small square
      thumbnail, per the scene/post size convention), `make_current!` (transactional
      exclusivity scoped to owner), abstract `owner`.
- [ ] `CharacterImage` (belongs_to :character) + `UserImage` (belongs_to :user); migrations
      with `current:boolean` + timestamps.
- [ ] `Character` has_many :character_images + `current_portrait` / `portrait_variant`.
      `User` has_many :user_images + `current_avatar` / `avatar_variant`.
- [ ] Shared controller concern `ImageLibrary` (index/create/set-current/destroy) driven by
      owner lookup. `CharacterImagesController` (nested under game/character) +
      `UserImagesController` (nested under profile). Routes.
- [ ] `CharacterImagePolicy` / `UserImagePolicy` — capability predicates (`manage?`)
      delegating to private role checks.
- [ ] `Shared::ImageLibraryComponent` (grid + upload + set-current/delete) and
      `Shared::ImageCropperComponent` (upload modal). Presenter-shaped data, never raw models.
      Register both in `.mutant.yml`.
- [ ] Presenters supplying `[{id:, url:, current:}]` shaped data for the library.
- [ ] `image_cropper_controller.js` Stimulus controller: pin Cropper.js via importmap,
      square crop → `canvas.toBlob()` → FormData upload. Run `importmap audit`.
- [ ] Render portrait on `characters/show`; avatar on profile; library entry point in forms.

### C. Tests & gates
- [ ] Model specs via shared example group exercised by both image models.
- [ ] Request specs per controller (upload, set-current, destroy, authz denials).
- [ ] Component specs (all states) for both new components.
- [ ] Policy specs (capability + role).
- [ ] Feature spec: upload→crop→set-current on BOTH viewports (1024px breakpoint).
- [ ] Sorbet sigils on every touched file; `srb tc` clean; rspec green before
      `bin/quality-metrics --check`; `bin/full-check`.
- [ ] Gem-maintenance check (repo rule).

## Resolved (owner decisions)

- **Image sizes:** define SEVERAL named variants on `UploadedImage::Model`, matching the
  repo's existing size convention (`variant(resize_to_limit: [width, nil], format: :jpeg,
  quality: 85)` — scene banner uses 1200, post inline 800). Concretely a large display
  variant + a small square thumbnail (roster/inline). Each render site picks the right
  named variant, exactly as scene-banner vs post-inline differ today. Since the crop is
  square-on-upload, thumbnails use `resize_to_fill: [n, n]`.
- **Library UI:** a **dedicated Portraits section** on the character (we are focused on the
  character), not inline in the edit form. Same shared component powers the User avatar
  section on the profile.
- **Upload path:** route through **`AttachmentUploader`** (R2 naming consistency with
  game_files/export).

## Cropper reference — hex-flower-app/src/components/TileCreator.jsx

The edit-modal + cropper to port (React → Stimulus, no React):
- Library: **Cropper.js** (`cropperjs`, the hex-flower app used `react-cropper` +
  `cropperjs@1.5.12`). Pin plain `cropperjs` via importmap; import its CSS.
- Flow: file input / drag-drop → `FileReader.readAsDataURL` → `new Cropper(img, {...})`
  with `aspectRatio: 1`, `viewMode: 1`, `dragMode: 'move'`, `autoCropArea: 1`,
  `background: false`, `responsive: true` → rotate/zoom controls (`cropper.rotate(±90)`,
  `cropper.zoom(±0.1)`) → live preview on the `crop` event → on save,
  `cropper.getCroppedCanvas().toBlob(cb, 'image/jpeg', quality)` and upload the Blob via
  FormData.
- Modal shell + Cancel/Save + Esc-to-close are all in TileCreator; re-implement as a
  ViewComponent-hosted modal driven by the Stimulus controller.
