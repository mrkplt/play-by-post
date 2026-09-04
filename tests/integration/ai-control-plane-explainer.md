# AI Control Plane — Explainer Page + Info Link (Fizzy #113)

Follow-up to #112 (PR #259). Users meet BYOK key entry, per-user/per-game consent,
and the shown/tagged/hidden display preference with little context. This adds a
single in-app explainer page and an info affordance pointing to it from the three
AI settings surfaces.

## Scope

1. **A standalone explainer page** at `/ai-control-plane` (authenticated), that
   explains, in plain prose:
   - **BYOK** — what "bring your own key" means, and *why we never see the
     plaintext key*: it's sealed in the browser against a per-key public key and
     only ever decrypted worker-side. The app cannot read it.
   - **Key resolution** — player-key → game pool → refuse. Player-facing AI is
     funded from the pool of members who authorized their own key for that game;
     if the pool is empty, generation is refused (there is no app-key fallback).
   - **The two consent gates** — the per-game GM toggle (a game enables an AI
     feature) *and* the per-user opt-in (a member authorizes their own key as a
     funding source for that game). Both must be satisfied.
   - **Display preference** — shown / tagged / hidden: how AI-generated content
     appears to *you* (a consumption setting, independent of who funds it).
   - **Provenance** — every AI generation is permanently recorded (who requested
     it, who funded it, the model, when). "AI-generated" is never guessed; it's
     tracked.

2. **An info affordance** (a small "help" icon + link) on the section-label
   action slot of each surface, linking to the page:
   - Profile AI settings (`profiles/show`, the "AI" section label)
   - Game AI settings (the `Shared::AiSummariesToggleComponent` card heading, and
     the "Game Preferences" label on `player_management/show`)
   - The BYOK key form (`Ui::ByokKeyFormComponent` heading)

## Non-goals / decisions

- **Info affordance is an inline text link, not a hover tooltip.** No tooltip
  primitive exists; the repo's established "info beside a heading" pattern is a
  `variant: :text` link in `Ui::SectionLabelComponent`'s `action` slot (see the
  "View API documentation" link in `profiles/_game_controls`). A hover tooltip
  would also be inaccessible on touch. We add a `help` icon to `Ui::IconComponent`
  and a small `Ui::InfoLinkComponent` (icon + label link) for reuse.
- **Authenticated, not public.** The card frames this as an *in-app* page reached
  from authenticated settings; there is no existing public-page pattern. Lives
  inside `authenticate :user`.
- **Content is a ViewComponent, not raw markup or a markdown blob.** Editorial
  content is fixed; `Shared::AiControlPlaneExplainerComponent` owns the section
  structure (never hand-written bespoke markup).

## Test plan

### Request spec — `spec/requests/ai_control_plane_spec.rb`
- `GET /ai-control-plane` while signed in → 200, renders the explainer.
- `GET /ai-control-plane` while signed out → redirects to sign in.

### Component spec — `spec/components/ui/info_link_component_spec.rb`
- Renders a link to the given `url` with the `help` icon and the label text.
- Default label; custom label override.

### Component spec — `spec/components/shared/ai_control_plane_explainer_component_spec.rb`
- Renders each of the five section headings (BYOK, resolution, consent, display,
  provenance).
- Renders prose body for each (a representative phrase per section).

### Icon spec — extend `spec/components/ui/icon_component_spec.rb`
- `ICON_MAP[:help]` maps to `"help-circle"`; `name: :help` renders.

### Manual browser check (both viewports, per docs/TESTING_NOTES.md)
- The info link appears beside each AI heading on Profile, Edit Game, and Game
  Settings, and lands on the explainer page. Page is readable at 375px and 1280px.
