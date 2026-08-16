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
#
# `title:` accepts either a bare String (the common case — plain white title,
# no crown) or a Title struct (see header_component/title.rb) when a screen
# needs the accent colour or the GM crown.
class Shared::HeaderComponent < ApplicationComponent
  extend T::Sig

  TitleArg = T.type_alias { T.any(String, Title) }

  sig do
    params(
      title: TitleArg,
      secondary_nav: T.nilable(ViewComponent::Base),
      gear: T.nilable(String),
      breadcrumbs: T.nilable(ViewComponent::Base)
    ).void
  end
  def initialize(title:, secondary_nav: nil, gear: nil, breadcrumbs: nil)
    @title = T.let(title.is_a?(Title) ? title : Title.new(text: title), Title)
    @secondary_nav = secondary_nav
    @gear = gear
    @breadcrumbs = breadcrumbs
  end

  sig { returns(String) }
  def title
    @title.text
  end

  sig { returns(T::Boolean) }
  def crown?
    @title.crown
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
    @title.accent ? "#{base} text-accent" : "#{base} text-white"
  end
end
