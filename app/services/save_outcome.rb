# typed: strict
# frozen_string_literal: true

# The result of an in-place save: what to tell the writer, which flash key it
# belongs under, and the status to answer with. Editors that keep the writer on
# the form (pages, notebook entries) all need the same three answers, and a
# bare boolean re-tested at each of them is the smell this replaces.
class SaveOutcome
  extend T::Sig

  SUCCESS = T.let({ flash_key: :notice, status: :ok }.freeze, T::Hash[Symbol, Symbol])
  FAILURE = T.let({ flash_key: :alert, status: :unprocessable_content }.freeze, T::Hash[Symbol, Symbol])

  # Names the subject rather than the wording: "Page updated." and "Could not
  # save the page." are both derivable from one noun, so a caller passes the
  # noun and gets both.
  sig { params(saved: T::Boolean, subject: String).returns(SaveOutcome) }
  def self.for(saved, subject)
    new(
      saved: saved,
      confirmation: "#{subject.capitalize} updated.",
      failure: "Could not save the #{subject}."
    )
  end

  sig { params(saved: T::Boolean, confirmation: String, failure: String).void }
  def initialize(saved:, confirmation:, failure:)
    @saved = saved
    @message = T.let(saved ? confirmation : failure, String)
    @answer = T.let(saved ? SUCCESS : FAILURE, T::Hash[Symbol, Symbol])
  end

  sig { returns(String) }
  attr_reader :message

  # Writes itself into the flash rather than handing out a key and a message
  # for the caller to reassemble. `flash.now` because the writer stays on the
  # form: the message belongs to this response, not to a navigation that never
  # happens.
  sig { params(flash: T.untyped).void }
  def announce_to(flash)
    flash.now[@answer.fetch(:flash_key)] = message
  end

  sig { returns(Symbol) }
  def status
    @answer.fetch(:status)
  end

  sig { returns(T::Boolean) }
  def saved?
    @saved
  end
end
