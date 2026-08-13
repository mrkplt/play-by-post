# typed: strict
# frozen_string_literal: true

# A lane move requested for a Campaign Notebook entry: which lane the entry is
# being dropped into, and how the caller expects to be answered.
#
# Both facts come off the same submitted form, and both are decisions about the
# request rather than about the entry — the status has to be checked against the
# known lanes before it reaches the model, and the response mode exists only
# because the board and the edit screen consume different responses.
class NotebookLaneMove
  extend T::Sig

  # The lane picker states where it was rendered; only the board can consume a
  # lane-swapping Turbo Stream, so anywhere else asks for a plain redirect.
  STANDALONE = T.let("standalone", String)

  sig { params(params: ActionController::Parameters).void }
  def initialize(params)
    @params = params
  end

  # The permitted status, rejecting anything outside the known lanes before it
  # can reach the model.
  sig { returns(ActionController::Parameters) }
  def attributes
    permitted = @params.require(:notebook_entry).permit(:status)
    raise ActionController::BadRequest, "invalid status" unless NotebookEntry::STATUSES.include?(permitted[:status])

    permitted
  end

  sig { returns(T::Boolean) }
  def standalone?
    @params[:response_mode].to_s == STANDALONE
  end
end
