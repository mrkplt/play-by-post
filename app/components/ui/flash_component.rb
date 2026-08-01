# typed: strict

# Renders the notice/alert flash banners inside the mobile frame's max-width
# gutter. Keeps flash markup (and its CSS) out of the application layout, which
# the quality gate does not allow to carry Tailwind classes.
class Ui::FlashComponent < ApplicationComponent
  extend T::Sig

  sig { params(notice: T.nilable(String), alert: T.nilable(String)).void }
  def initialize(notice: nil, alert: nil)
    @notice = notice
    @alert = alert
  end

  sig { returns(T.nilable(String)) }
  attr_reader :notice

  sig { returns(T.nilable(String)) }
  attr_reader :alert

  sig { returns(T::Boolean) }
  def any?
    @notice.present? || @alert.present?
  end
end
