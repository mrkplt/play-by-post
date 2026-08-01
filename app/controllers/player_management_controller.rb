# typed: true

class PlayerManagementController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_gm!

  sig { void }
  def show
    @members = @game.game_members.where.not(status: "banned").where(role: "player").includes(:user)
    @member_display_names = @members.each_with_object({}) { |m, h| h[m.user_id] = UserPresenter.new(m.user).display_name_or_email }
    @member_characters = character_names_by_user
    @pending_invitations = @game.invitations.pending.order(created_at: :desc)
    @invitation = Invitation.new
  end

  private

  # First active character name per user, for the Members list subtitle.
  sig { returns(T::Hash[Integer, String]) }
  def character_names_by_user
    @game.characters.active.each_with_object({}) do |c, h|
      h[c.user_id] ||= c.name
    end
  end

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage players."
    end
  end
end
