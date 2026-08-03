# typed: true

class PlayerManagementController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_access!
  after_action :verify_authorized

  sig { void }
  def show
    authorize @game, :manage_players?
    @game_presenter = GamePresenter.new(@game, current_user)

    if policy(@game).update?
      @members = @game.game_members.where.not(status: "banned").where(role: "player").includes(:user)
      @member_display_names = @members.each_with_object({}) { |m, h| h[m.user_id] = UserPresenter.new(m.user).display_name_or_email }
      @member_characters = character_names_by_user
      @pending_invitations = @game.invitations.pending.order(created_at: :desc)
    end

    @export_receipt = GameExportRequest.valid_receipt_for(current_user, @game)
    @export_notice = @export_receipt ? T.unsafe(view_context).last_export_notice(@export_receipt) : nil
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
  def require_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).manage_players?
  end
end
