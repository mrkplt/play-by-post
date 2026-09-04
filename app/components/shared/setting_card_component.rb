# typed: strict

# The shared "settings card" body for a GM game-flag toggle rendered as a card
# (the Edit Game screen): a section label, then a card holding a status sentence
# and the flip button. Both Shared::AiSummariesToggleComponent (its card branch)
# and Shared::PlayerContributionsToggleComponent render this rather than
# repeating the identical card/paragraph/button markup — the class strings were
# byte-identical, so the presentation is one component parameterized by content
# (per docs/COMPONENT_CONVENTIONS "parameterize variations"), not forked twice.
#
# The status sentence is passed as the block body so each caller keeps its own
# wording (and the emphasised on/off word). The caller owns the `wrapper_id`
# div (so Games::SettingsController can replace the control in place after a
# flip) — AI summaries shares that id between its row and card presentations, so
# it must sit outside this card, not inside it.
class Shared::SettingCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(title: String, toggle_label: String, toggle_path: String).void }
  def initialize(title:, toggle_label:, toggle_path:)
    @title = T.let(title, String)
    @toggle_label = T.let(toggle_label, String)
    @toggle_path = T.let(toggle_path, String)
  end

  sig { returns(String) }
  attr_reader :title

  sig { returns(String) }
  attr_reader :toggle_label

  sig { returns(String) }
  attr_reader :toggle_path
end
