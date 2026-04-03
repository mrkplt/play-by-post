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

class Devise::Passwordless::SessionsController
  sig { returns(T.untyped) }
  def resource; end

  sig { params(value: T.untyped).returns(T.untyped) }
  def resource=(value); end

  sig { params(resource: T.untyped, opts: T.untyped).void }
  def send_magic_link(resource, **opts); end

  sig { returns(T.untyped) }
  def params; end

  sig { returns(T.untyped) }
  def flash; end

  sig { params(args: T.untyped, kwargs: T.untyped, blk: T.untyped).returns(T.untyped) }
  def render(*args, **kwargs, &blk); end

  sig { returns(String) }
  def root_path; end
end
