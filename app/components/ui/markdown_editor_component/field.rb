# typed: strict

# The editor's textarea-level configuration: size (rows), current value and
# placeholder, whether it is required, extra data attributes to merge onto
# the textarea, and a wrapper class that positions (not styles) the editor.
# Grouping these keeps Ui::MarkdownEditorComponent's own parameter list to
# `binding:` (the form/field pair), `config:` (layout — see config.rb) and
# this bundle.
class Ui::MarkdownEditorComponent::Field < T::Struct
  extend T::Sig

  const :rows, Integer, default: 5
  const :value, T.nilable(String), default: nil
  const :placeholder, T.nilable(String), default: nil
  const :requirement, Symbol, default: :optional
  const :data, T::Hash[Symbol, T.untyped], default: {}
  const :wrapper_class, String, default: ""

  sig { returns(T::Boolean) }
  def required?
    requirement == :required
  end
end
