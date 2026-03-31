# typed: true

class ApplicationComponent < ViewComponent::Base
  extend T::Sig
  extend T::Helpers
  abstract!
end
