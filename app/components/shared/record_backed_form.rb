# typed: strict

# The plumbing every record-backed form component repeats: is this a new record,
# does it have errors, and what are the messages. Including components implement
# `record` and get the three delegations.
#
# Deliberately a plain module rather than an ActiveSupport::Concern — this
# project does not use concerns, and `bin/check-concerns` enforces that.
#
# This is delegation only. It is not a base class for forms: `form_id`,
# `back_href` and `submit_label` look shared and are not — they are where each
# form's lifecycle differences live, and folding them in here would re-couple
# the models that own them.
module Shared::RecordBackedForm
  extend T::Sig
  extend T::Helpers

  abstract!

  # The presenter the form is built around. Untyped because each form is built
  # around a different presenter and they share no common ancestor declaring
  # these three methods.
  sig { abstract.returns(T.untyped) }
  def record; end

  sig { returns(T::Boolean) }
  def new_record?
    record.new_record?
  end

  sig { returns(T::Boolean) }
  def errors?
    record.errors?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    record.error_messages
  end
end
