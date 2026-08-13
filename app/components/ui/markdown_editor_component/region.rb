# typed: strict

# The interface every optional region around the markdown textarea implements.
#
# The editor lays out a textarea with regions above it (the formatting toolbar)
# and below it (the live preview). It does not know what any particular region
# is — it asks each one where it sits and renders it. Turning a region off is
# omitting it from the config's collection, not passing a boolean the editor
# has to branch on.
module Ui::MarkdownEditorComponent::Region
  extend T::Sig
  extend T::Helpers

  interface!

  # Where this region sits relative to the textarea.
  sig { abstract.returns(Symbol) }
  def placement; end

  # The component to render for this region.
  sig { abstract.returns(ViewComponent::Base) }
  def component; end
end
