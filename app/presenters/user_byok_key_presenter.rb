# typed: strict

# The BYOK (bring-your-own OpenRouter key) facts a user's Profile screen
# needs: whether a key is present, and the public half of the keypair the
# browser encrypts to (Ui::ByokKeyFormComponent's two inputs). Split out of
# UserPresenter (which was pushing past reek's method-count ceiling) rather
# than folded in as more UserPresenter methods — mirrors
# UserAvatarLibraryPresenter, a second small facet already split out the
# same way.
class UserByokKeyPresenter < BasePresenter
  extend T::Sig

  sig { params(model: User, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # Whether this user has a BYOK OpenRouter key configured. Delegates to the
  # presence seam (User#ai_key_present?) rather than re-deriving it, so the
  # two stay in lockstep.
  sig { returns(T::Boolean) }
  def present?
    @model.ai_key_present?
  end

  # The PEM public half of this user's BYOK keypair, once
  # AiKeypairGenerationJob has created it — nil until then (the "Set up
  # encryption" step hasn't run, or its job hasn't completed yet).
  sig { returns(T.nilable(String)) }
  def public_key_pem
    keypair&.public_key
  end

  private

  sig { returns(T.nilable(AiKeypair)) }
  def keypair
    @keypair ||= T.let(AiKeypair.find_by(owner: @model), T.nilable(AiKeypair))
  end
end
