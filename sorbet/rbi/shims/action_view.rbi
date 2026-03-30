# typed: true

module ActionView
  module Helpers
    module SanitizeHelper
      sig { params(html: T.nilable(String), options: T.untyped).returns(T.nilable(String)) }
      def sanitize(html, options = {}); end
    end
  end
end

module ApplicationHelper
  include ActionView::Helpers::SanitizeHelper
end
