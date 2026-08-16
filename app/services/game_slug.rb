# typed: strict

# Builds a game's URL slug: a name-derived, hyphenated base plus a random
# alphanumeric suffix (e.g. "dragons-of-icespire-peak-a1b2c3"). The suffix
# guarantees uniqueness even when two games share a name, so a game's URL never
# collides and never exposes the raw database id. Pure and stateless — Game
# calls this on the create path to assign a slug once, and the value is fixed
# for the life of the game.
module GameSlug
  extend T::Sig

  # Length of the random alphanumeric suffix appended to the name-derived base.
  SUFFIX_LENGTH = 6

  # When the name parameterizes to nothing (all non-slug-able characters), the
  # suffix stands alone so the slug is never empty or leading-dashed.
  sig { params(name: T.nilable(String)).returns(String) }
  def self.build(name)
    base = name.to_s.parameterize
    base.empty? ? generate_suffix : "#{base}-#{generate_suffix}"
  end

  sig { returns(String) }
  def self.generate_suffix
    SecureRandom.alphanumeric(SUFFIX_LENGTH).downcase
  end
end
