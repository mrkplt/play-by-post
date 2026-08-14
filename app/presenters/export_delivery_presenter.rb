# typed: strict

# View model for the export emails: who they greet, which game (if any) was
# exported, and the download link with its expiry. Wraps the recipient's
# UserPresenter — the export is about the user, not the game, which may be
# absent for an all-games export.
class ExportDeliveryPresenter < BasePresenter
  extend T::Sig

  sig { params(model: UserPresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The greeting name: display name when set, otherwise the full email.
  sig { returns(String) }
  def recipient_name
    @model.display_name_or_full_email
  end

  # The exported game, or nil for an all-games export.
  sig { returns(T.nilable(GamePresenter)) }
  def game
    @options.fetch(:game, nil)
  end

  sig { returns(String) }
  def download_url
    @options.fetch(:download_url)
  end

  sig { returns(Integer) }
  def expires_days
    @options.fetch(:expires_days)
  end
end
