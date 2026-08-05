# typed: strict

# A formatting toolbar for markdown textareas: bold, italic, heading, quote,
# lists, link and inline code. Purely presentational — every button drives the
# `markdown-toolbar` Stimulus controller, which mutates the associated textarea
# and dispatches an input event so any paired live preview refreshes. It holds
# no domain data and can sit above any `markdown-editor` textarea.
class Shared::MarkdownToolbarComponent < ApplicationComponent
  extend T::Sig

  Button = T.type_alias { { action: String, label: String, title: String, label_class: String } }

  BUTTONS = T.let([
    { action: "bold",       label: "B",    title: "Bold",           label_class: "font-bold" },
    { action: "italic",     label: "I",    title: "Italic",         label_class: "italic" },
    { action: "heading",    label: "H",    title: "Heading",        label_class: "font-bold" },
    { action: "quote",      label: "“", title: "Quote",        label_class: "" },
    { action: "bulletList", label: "• List", title: "Bulleted list", label_class: "" },
    { action: "numberList", label: "1. List", title: "Numbered list", label_class: "" },
    { action: "link",       label: "Link", title: "Insert link",    label_class: "" },
    { action: "code",       label: "Code", title: "Inline code",    label_class: "font-mono" }
  ].freeze, T::Array[Button])

  sig { returns(T::Array[Button]) }
  def buttons
    BUTTONS
  end
end
