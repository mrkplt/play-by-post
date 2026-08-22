# typed: strict

# View model for one game's row in the profile's "Fund AI for your games"
# matrix: the game name, and one cell per pool-fundable feature. Each cell is a
# component-ready toggle (Shared::KeyContributionMatrixComponent::Offered /
# Available) that owns its own presentation, so neither this row nor the
# component branches on a `contributing` flag. Parallels ApiTokenRowPresenter
# (one game, per-column state + a route).
class KeyContributionRowPresenter < BasePresenter
  extend T::Sig

  Cell = Shared::KeyContributionMatrixComponent::Cell
  Offered = Shared::KeyContributionMatrixComponent::Offered
  Available = Shared::KeyContributionMatrixComponent::Available

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(T::Array[Cell]) }
  def cells
    Ai::Feature.pool_fundable.map { |feature| build_cell(feature) }
  end

  private

  sig { params(feature: Ai::Feature).returns(Cell) }
  def build_cell(feature)
    name = feature.name
    return offered_cell(feature) if contributed_features.include?(name)

    Available.new(label: feature.label, feature: name, path: urls.game_key_contributions_path(@model))
  end

  sig { params(feature: Ai::Feature).returns(Cell) }
  def offered_cell(feature)
    name = feature.name
    Offered.new(label: feature.label, feature: name, path: urls.game_key_contribution_path(@model, name))
  end

  # The features the viewer already funds for this game (a Set of names,
  # supplied by the presenter builder so the row does no query).
  sig { returns(T::Set[String]) }
  def contributed_features
    @options.fetch(:contributed_features)
  end

  sig { returns(T.untyped) }
  def urls
    @options.fetch(:urls)
  end
end
