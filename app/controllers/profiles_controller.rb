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
    return if performed?

    RssToken.for_user_scope(current_user, game).destroy_all
    RssToken.create!(user: current_user, game: game)
    redirect_to profile_path, notice: "RSS token generated."
  end

  sig { void }
  def revoke_rss_token
    authorize @profile, :manage?
    game = rss_scope_game
    return if performed?

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

  # Resolves the optional game_id for an RSS scope action. Blank means the
  # account-level scope (nil game). A present game_id must name a game the user
  # is a non-banned member of, otherwise the action is refused.
  sig { returns(T.nilable(Game)) }
  def rss_scope_game
    game_id = params[:game_id]
    return nil if game_id.blank?

    membership = current_user.game_members
      .where.not(status: "banned")
      .find_by(game_id: game_id)

    unless membership
      redirect_to profile_path, alert: "You are not a member of that game."
      return nil
    end

    membership.game
  end
end
