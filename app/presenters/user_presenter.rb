# typed: strict

class UserPresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::DateHelper

  sig { returns(String) }
  def display_name_or_email
    @model.display_name || @model.email.split("@").first
  end

  # The greeting name for an email: display name when set, otherwise the full
  # email address. Distinct from #display_name_or_email, which falls back to
  # the local part only — fine for a compact UI chip, wrong in prose.
  sig { returns(String) }
  def display_name_or_full_email
    @model.display_name.presence || @model.email
  end

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  # This user as a `[label, value]` pair for an owner/player select — the
  # form's display name (falling back to the full email, unlike
  # #display_name_or_email's local-part-only fallback used for compact
  # display elsewhere) paired with the user's id.
  sig { returns([ String, Integer ]) }
  def select_option
    [ @model.display_name || @model.email, T.must(id) ]
  end

  # The "Export All Games" row's subtitle: the last-export notice when this
  # user has a valid all-games receipt, otherwise generic delivery/expiry
  # copy. Mirrors GamePresenter#export_notice for the single-game case.
  sig { returns(String) }
  def export_all_games_notice
    receipt = GameExportRequest.valid_receipt_for(@model, nil)
    return "Last export: #{time_ago_in_words(T.must(receipt.succeeded_at))} ago" if receipt

    "You'll receive an email with a download link within a few minutes; the link expires after 7 days."
  end

  sig { params(limit: T.nilable(Integer)).returns(ActiveRecord::Relation) }
  def games_by_recent_activity(limit: nil)
    query = @model.games
      .where.not("game_members.status" => [ "removed", "banned" ])
      .left_joins(:scenes)
      .select("games.id, games.name, games.created_at, MAX(scenes.updated_at) as latest_activity")
      .group("games.id", "games.name", "games.created_at")
      .order(Arel.sql("COALESCE(MAX(scenes.updated_at), games.created_at) DESC"))

    query = query.limit(limit) if limit
    query
  end

  # Games the nav drawer lists: every membership except banned (banned games
  # disappear entirely), each paired with its membership so the drawer can pick
  # the right status icon (GM crown / former moon / plain). Ordered by name.
  # Soft-deleted games are dropped (Game.all carries the default scope) — their
  # membership survives but has no visible game.
  sig { returns(T::Array[GameMember]) }
  def drawer_memberships
    @model.game_members
      .where.not(status: "banned")
      .where(game_id: Game.all)
      .includes(:game)
      .sort_by { |member| member.game&.name.to_s }
  end

  # The profile's RSS Feeds section, one row per non-banned game membership
  # paired with this user's rss-scoped token for that game (if any). `urls:`
  # (the constructing controller) is threaded onto each row so it can build
  # its own feed/revoke/create routes without the component reaching for one.
  sig { params(urls: T.untyped).returns(T::Array[GameFeedRowPresenter]) }
  def feed_rows(urls:)
    tokens_by_game_id = @model.api_tokens.where(scope: "rss").index_by(&:game_id)
    feed_memberships.filter_map do |membership|
      game = membership.game
      next unless game

      GameFeedRowPresenter.new(game, token: tokens_by_game_id[game.id], urls: urls)
    end
  end

  # The profile's "API tokens" section rows (ApiTokensPresenter, a collection
  # presenter over the profile-listing memberships).
  sig { params(urls: T.untyped).returns(T::Array[ApiTokenRowPresenter]) }
  def api_token_rows(urls:)
    ApiTokensPresenter.new(feed_memberships, user: @model, urls: urls).rows
  end

  # The profile's "fund AI for your games" section rows (KeyContributionsPresenter).
  # URLs come from the construction helpers so the view reads this off the
  # presenter with no controller ivar.
  sig { returns(T::Array[KeyContributionRowPresenter]) }
  def key_contribution_rows
    KeyContributionsPresenter.new(feed_memberships, user: @model, urls: @options.fetch(:helpers)).rows
  end

  # The user's avatar facet — the library items the profile cropper renders,
  # the upload route, and the current-avatar URL the identity block uses —
  # exposed as one accessor so those cohesive reads live on UserAvatarLibrary
  # Presenter (which holds the helpers) rather than as three delegators here.
  sig { returns(UserAvatarLibraryPresenter) }
  def avatar
    @avatar ||= T.let(
      UserAvatarLibraryPresenter.new(user: @model, helpers: @options.fetch(:helpers)),
      T.nilable(UserAvatarLibraryPresenter)
    )
  end

  # The BYOK (bring-your-own OpenRouter key) facts the Profile screen's
  # Ui::ByokKeyFormComponent needs — see UserByokKeyPresenter.
  sig { returns(UserByokKeyPresenter) }
  def byok_key
    @byok_key ||= T.let(UserByokKeyPresenter.new(@model), T.nilable(UserByokKeyPresenter))
  end

  private

  sig { returns(T.untyped) }
  def feed_memberships
    @model.game_members.for_profile_listing
  end
end
