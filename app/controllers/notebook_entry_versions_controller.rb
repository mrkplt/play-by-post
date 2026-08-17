# typed: strict

class NotebookEntryVersionsController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  sig { void }
  def show
    authorize version
    @version_presenter = T.let(NotebookEntryVersionPresenter.new(version), T.nilable(NotebookEntryVersionPresenter))
    @entry_presenter = T.let(NotebookEntryPresenter.new(notebook_entry), T.nilable(NotebookEntryPresenter))
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  private

  # No before_action ivar: the route-nested records (game -> entry -> version)
  # are controller-internal plumbing, never read by a template as raw models, so
  # under `# typed: strict` an ivar holding them would be a raw model at the view
  # boundary. Each accessor re-resolves from params; #show is the only action.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { returns(NotebookEntry) }
  def notebook_entry
    game.notebook_entries.find_by!(slug: params[:notebook_entry_slug])
  end

  sig { returns(NotebookEntryVersion) }
  def version
    notebook_entry.notebook_entry_versions.find(params[:id])
  end
end
