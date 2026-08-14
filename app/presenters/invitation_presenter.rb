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
