# typed: true

# The GM-designated environment/setting page behaviour a Game gains from its
# nullable `environment_page` association: the validation that the page belongs
# to this game, and the reader that yields its body for AI character-portrait
# prompt composition (Ai::PortraitPrompt).
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern — bin/check-concerns enforces that. The association
# macro and the `validate` hook stay declared on Game, where the wiring is
# visible and statically typed; only the behaviour lives here.
class Game
  module EnvironmentPage
    extend T::Sig

    # The environment page's markdown body, or nil when none is designated —
    # the setting portion of a portrait prompt.
    sig { returns(T.nilable(String)) }
    def environment_prompt
      T.bind(self, Game)
      environment_page&.body
    end

    private

    # The designated environment page must be one of this game's own pages — a
    # GM cannot point a portrait prompt at another game's content.
    sig { void }
    def environment_page_belongs_to_game
      T.bind(self, Game)
      page = environment_page
      return if page.nil?
      return if page.game_id == id

      errors.add(:environment_page, "must be a page in this game")
    end
  end
end
