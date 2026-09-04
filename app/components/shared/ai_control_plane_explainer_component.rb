# typed: strict

# The editorial body of the AI Control Plane explainer page (Fizzy #113). Holds
# the five fixed sections that explain how AI works in the app — BYOK custody,
# key resolution, the two consent gates, the display preference, and provenance
# — as structured content (heading + paragraphs per section), so the page view
# composes one component rather than hand-writing bespoke prose markup.
#
# Content is fixed editorial copy, not model-derived, so it lives in the
# component (a component owns its content). SECTIONS is the single source of the
# copy; the template enumerates it.
class Shared::AiControlPlaneExplainerComponent < ApplicationComponent
  extend T::Sig

  class Section < T::Struct
    const :heading, String
    const :paragraphs, T::Array[String]
  end

  SECTIONS = T.let([
    Section.new(
      heading: "Bring your own key (BYOK)",
      paragraphs: [
        "AI features are funded by OpenRouter API keys that people bring themselves — there is no shared house key. You add your key on your Profile, and it pays for the AI work you and (if you choose) your games ask for.",
        "We never see your key in plaintext. When you save it, your browser seals it against a public key that belongs only to that stored key, and the sealed envelope is all that reaches us. The key is decrypted only inside the background worker at the moment it is used — never on a page, never in a log, never by us."
      ]
    ),
    Section.new(
      heading: "How a key is chosen",
      paragraphs: [
        "When a game runs an AI feature, it draws from a pool: the members of that game who have authorized their own key as a funding source for it. A key is picked from the pool, and if it can't pay (declined, out of credit, rate-limited) the next one is tried.",
        "If the pool is empty, generation is simply refused. There is no fallback to an app-owned key for player-facing AI — if nobody has offered to fund a feature, it does not run."
      ]
    ),
    Section.new(
      heading: "Two consent gates",
      paragraphs: [
        "An AI feature runs only when two separate consents line up. First, the GM enables the feature for the game — a per-game toggle in Game Settings. Second, each member decides individually whether to authorize their own key as a funding source for that game.",
        "Enabling a feature does not spend anyone's key by itself, and authorizing your key does not turn a feature on. Both have to be true, and either can be withdrawn at any time."
      ]
    ),
    Section.new(
      heading: "How AI content appears to you",
      paragraphs: [
        "Separately from funding, you control how AI-generated content shows up for you, on your Profile: Shown renders it like anything else, Tagged renders it with a prominent \"AI-generated\" badge, and Hidden filters it out of your view entirely.",
        "This is a reading preference — it changes what you see, not what other people see and not who pays for generation."
      ]
    ),
    Section.new(
      heading: "Provenance is always recorded",
      paragraphs: [
        "Every AI generation is written to a permanent, append-only record: which feature produced it, which model was used, who requested it, who funded it, and when. That record is never edited or deleted.",
        "So \"AI-generated\" is never a guess. The display preference above decides whether a badge is shown, but the underlying provenance is tracked regardless of how you choose to view it."
      ]
    )
  ].freeze, T::Array[Section])
end
