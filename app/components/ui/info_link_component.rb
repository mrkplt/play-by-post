# typed: strict

# Small inline "info" affordance: a help-circle icon plus a short label, styled
# as a borderless text link, that sits in a section label's `action` slot and
# points at an explainer page. This is the app's info-beside-a-heading pattern
# (a text link, not a hover tooltip — no tooltip primitive exists, and a hover
# target is inaccessible on touch), matching the "View API documentation" link
# already riding Ui::SectionLabelComponent's action slot.
class Ui::InfoLinkComponent < ApplicationComponent
  extend T::Sig

  DEFAULT_LABEL = T.let("How this works", String)

  sig { params(url: String, label: String).void }
  def initialize(url:, label: DEFAULT_LABEL)
    @url = url
    @label = label
  end

  sig { returns(String) }
  attr_reader :url

  sig { returns(String) }
  attr_reader :label
end
