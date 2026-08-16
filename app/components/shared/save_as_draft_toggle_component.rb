# typed: strict

# The "save as draft" toggle shared by the page and scene-summary editors, and
# the page create form. In `autosave` mode the checkbox is wired to the draft
# Stimulus controller (which intercepts submit to save the record as a draft);
# in `field` mode it is a plain named checkbox that submits `<param>[draft]` on
# create. Starts checked when the record is already a draft. Owning the toggle
# here keeps its label + checkbox markup in one place.
class Shared::SaveAsDraftToggleComponent < ApplicationComponent
  extend T::Sig

  LABEL = "Save as draft (only you can see it until you publish)"
  CHECKBOX_CLASS = "w-[18px] h-[18px] accent-accent"

  sig { params(checked: T::Boolean, param: T.nilable(String)).void }
  def initialize(checked:, param: nil)
    @checked = T.let(checked, T::Boolean)
    @param = T.let(param, T.nilable(String))
  end

  sig { returns(T::Boolean) }
  def checked?
    @checked
  end

  # When set, render a plain named checkbox (`<param>[draft]`) for a create
  # form; otherwise render the autosave checkbox wired to the draft controller.
  sig { returns(T::Boolean) }
  def field_mode?
    !@param.nil?
  end

  sig { returns(String) }
  def field_name
    "#{T.must(@param)}[draft]"
  end
end
