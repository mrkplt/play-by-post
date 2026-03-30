# typed: true

module Devise
  module Models
    module ClassMethods
      sig { params(modules: Symbol).void }
      def devise(*modules); end
    end
  end
end

class ApplicationRecord
  extend Devise::Models::ClassMethods
end

module Devise
  module Controllers
    module Helpers
      # All controllers require authenticate_user! before_action,
      # so current_user is guaranteed non-nil in controller actions.
      sig { returns(User) }
      def current_user; end
    end
  end
end

class ApplicationController
  include Devise::Controllers::Helpers
end
