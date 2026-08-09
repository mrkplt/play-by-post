# typed: strict

# The universal dark header rendered at the top of every in-game and
# top-level screen: a hamburger (opens the nav drawer — always present),
# an optional GM crown, the title, and three independently-nilable extras:
#
#   secondary_nav: a component instance (e.g. Shared::GameNavComponent) or nil
#   gear:          a path (renders a settings IconButtonComponent) or nil
#   breadcrumbs:   a component instance (e.g. Shared::BreadcrumbsComponent) or nil
#
# Collapses Shared::GameHeaderComponent and Shared::PageHeaderComponent into
# one shape: this is the "one header for every screen" fix — a screen passes
# in only the pieces relevant to it; there is no hand-rolled per-screen
# layout and no `leading: :back` branch (the hamburger is always rendered).
class Shared::HeaderComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      title: String,
      secondary_nav: T.nilable(ViewComponent::Base),
      gear: T.nilable(String),
      breadcrumbs: T.nilable(ViewComponent::Base),
      accent_title: T::Boolean,
      crown: T::Boolean
    ).void
  end
  def initialize(title:, secondary_nav: nil, gear: nil, breadcrumbs: nil, accent_title: false, crown: false)
    @title = title
    @secondary_nav = secondary_nav
    @gear = gear
    @breadcrumbs = breadcrumbs
    @accent_title = accent_title
    @crown = crown
  end

  sig { returns(String) }
  attr_reader :title

  sig { returns(T::Boolean) }
  def crown?
    @crown
  end

  sig { returns(T::Boolean) }
  def gear?
    @gear.present?
  end

  sig { returns(String) }
  def gear_path
    T.must(@gear)
  end

  sig { returns(T::Boolean) }
  def breadcrumbs?
    @breadcrumbs.present?
  end

  sig { returns(ViewComponent::Base) }
  def breadcrumbs
    T.must(@breadcrumbs)
  end

  sig { returns(T::Boolean) }
  def secondary_nav?
    @secondary_nav.present?
  end

  sig { returns(ViewComponent::Base) }
  def secondary_nav
    T.must(@secondary_nav)
  end

  sig { returns(String) }
  def title_classes
    base = "font-bold text-[19px] m-0 truncate"
    @accent_title ? "#{base} text-accent" : "#{base} text-white"
  end
end
