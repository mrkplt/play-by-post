# typed: strict

# A dark page header for non-game screens (Dashboard, Profile): a leading tap
# target (hamburger to open the nav drawer, or a back link) and a title. No
# tabs, no gear. Title is gold on the Dashboard, white elsewhere.
class Shared::PageHeaderComponent < ApplicationComponent
  extend T::Sig

  sig { params(title: String, leading: Symbol, back_href: T.nilable(String), accent_title: T::Boolean).void }
  def initialize(title:, leading: :menu, back_href: nil, accent_title: false)
    @title = title
    @leading = leading
    @back_href = back_href
    @accent_title = accent_title
  end

  sig { returns(String) }
  attr_reader :title

  sig { returns(T::Boolean) }
  def back?
    @leading == :back
  end

  sig { returns(String) }
  def back_href
    T.must(@back_href)
  end

  sig { returns(String) }
  def title_classes
    base = "font-bold text-[19px] m-0 truncate"
    @accent_title ? "#{base} text-accent" : "#{base} text-white"
  end
end
