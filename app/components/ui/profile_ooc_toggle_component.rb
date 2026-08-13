# typed: strict

class Ui::ProfileOocToggleComponent < ApplicationComponent
  extend T::Sig

  sig { params(hide_ooc: T::Boolean, toggle_url: String).void }
  def initialize(hide_ooc:, toggle_url:)
    @hide_ooc = hide_ooc
    @toggle_url = toggle_url
  end

  sig { returns(T::Boolean) }
  def hide_ooc?
    @hide_ooc
  end

  sig { returns(String) }
  def toggle_url
    @toggle_url
  end

  sig { returns(String) }
  def aria_label
    hide_ooc? ? "Show OOC posts by default" : "Hide OOC posts by default"
  end
end
