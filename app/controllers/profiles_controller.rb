# typed: true

class ProfilesController < ApplicationController
  extend T::Sig

  before_action :set_profile
  after_action :verify_authorized

  sig { void }
  def show
    authorize @profile
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(:game)
      .order("games.name")
    @export_all_receipt = GameExportRequest.valid_receipt_for(current_user, nil)
  end

  sig { void }
  def edit
    authorize @profile
  end

  sig { void }
  def update
    authorize @profile
    @profile.display_name = params[:user_profile][:display_name]

    if @profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    authorize @profile, :manage?
    @profile.update!(hide_ooc: !@profile.hide_ooc?)
    head :ok
  end

  sig { void }
  def generate_rss_token
    authorize @profile, :manage?
    game = rss_scope_game

    RssToken.for_user_scope(current_user, game).destroy_all
    RssToken.create!(user: current_user, game: game)
    redirect_to profile_path, notice: "RSS token generated."
  end

  sig { void }
  def revoke_rss_token
    authorize @profile, :manage?
    game = rss_scope_game

    RssToken.for_user_scope(current_user, game).destroy_all
    redirect_to profile_path, notice: "RSS token revoked."
  end

  sig { void }
  def export_all
    authorize @profile, :manage?
    receipt = GameExportRequest.valid_receipt_for(current_user, nil)

    if receipt
      ExportDelivery.email_download_link(receipt)
    else
      request = GameExportRequest.create!(user: current_user, game: nil)
      ExportJob.perform_later(request.id)
    end

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { void }
  def set_profile
    @profile = current_user.user_profile || current_user.build_user_profile
  end

  # Resolves the game an RSS scope action targets. Every token is game-scoped,
  # so game_id is required. The game is authorized through GamePolicy#show?
  # (viewable member: GM, active, or removed) — Pundit raises NotAuthorizedError
  # for a banned or non-member, refusing the action.
  sig { returns(Game) }
  def rss_scope_game
    game = Game.find(params.require(:game_id))
    authorize game, :show?
    game
  end
end
