# typed: strict

# The Game form's submit-side configuration: what the submit button says,
# where Cancel goes, an optional confirm prompt, and an optional note shown
# above the actions (the "you become the GM" line shown only on creation).
# Grouping these keeps Shared::GameFormComponent's own parameter list to the
# form's actual subject (`game:`) plus this one bundle.
class Shared::GameFormComponent::Submission < T::Struct
  const :label, String
  const :cancel_href, String
  const :note, T.nilable(String), default: nil
  const :confirm, T.nilable(String), default: nil
end
