# typed: strict

# A card with a heading and a markdown body, used to render a page's content and
# a historical page version's content identically. Falls back to a placeholder
# when the body is blank. Owning this here keeps the card markup in one place
# rather than duplicated across the page detail and version-detail views.
class Shared::TitledCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(title: String, body: String, empty_notice: String).void }
  def initialize(title:, body:, empty_notice:)
    @title = T.let(title, String)
    @body = T.let(body, String)
    @empty_notice = T.let(empty_notice, String)
  end

  sig { returns(String) }
  attr_reader :title

  sig { returns(String) }
  attr_reader :body

  sig { returns(String) }
  attr_reader :empty_notice

  sig { returns(T::Boolean) }
  def body?
    body.present?
  end
end
