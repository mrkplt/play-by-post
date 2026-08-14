# typed: strict

# View model for a pending invitation row on the Roster tab: the invited
# email, a "Sent N ago" label, and the resend/cancel routes. `game:` and
# `urls:` (the constructing controller) are supplied at construction so the
# presenter never builds a route helper of its own.
class InvitationPresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::DateHelper

  sig { params(model: Invitation, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def email
    @model.email
  end

  # Who sent this invitation, for the invite email's sign-off. Their display
  # name when set, otherwise their email — resolved here so the template does
  # not reach through the invitation to its inviter, nor carry the fallback.
  # The accept link for the invite email — supplied at construction because
  # the token-signed URL is the mailer's to build.
  sig { returns(String) }
  def accept_url
    @options.fetch(:accept_url)
  end

  sig { returns(String) }
  def inviter_name
    UserPresenter.new(@model.invited_by).display_name_or_full_email
  end

  sig { returns(String) }
  def cancel_path
    @options.fetch(:urls).game_player_management_invitation_path(@options.fetch(:game), @model)
  end

  sig { returns(String) }
  def resend_path
    @options.fetch(:urls).resend_game_player_management_invitation_path(@options.fetch(:game), @model)
  end

  sig { returns(String) }
  def sent_label
    "Sent #{time_ago_in_words(@model.created_at)} ago"
  end
end
