import { Controller } from "@hotwired/stimulus"

// Formatting controls for a markdown textarea. Each action mutates the current
// selection (inline styles) or the current line(s) (block styles) in place,
// restores focus and a sensible selection, and dispatches an input event so a
// paired markdown-preview controller refreshes.
export default class extends Controller {
  static targets = ["input"]

  bold(event)       { this.wrapSelection(event, "**", "**", "bold text") }
  italic(event)     { this.wrapSelection(event, "_", "_", "italic text") }
  code(event)       { this.wrapSelection(event, "`", "`", "code") }
  heading(event)    { this.prefixLines(event, "## ") }
  quote(event)      { this.prefixLines(event, "> ") }
  bulletList(event) { this.prefixLines(event, "- ") }
  numberList(event) { this.prefixLines(event, "1. ") }

  link(event) {
    event.preventDefault()
    const input = this.inputTarget
    const { selectionStart, selectionEnd, value } = input
    const selected = value.slice(selectionStart, selectionEnd) || "link text"
    const replacement = `[${selected}](url)`
    input.value = value.slice(0, selectionStart) + replacement + value.slice(selectionEnd)
    // Select the "url" placeholder so the user can type the destination over it.
    const urlStart = selectionStart + selected.length + 3
    this.focusRange(urlStart, urlStart + 3)
    this.notify()
  }

  wrapSelection(event, before, after, placeholder) {
    event.preventDefault()
    const input = this.inputTarget
    const { selectionStart, selectionEnd, value } = input
    const hadSelection = selectionEnd > selectionStart
    const selected = hadSelection ? value.slice(selectionStart, selectionEnd) : placeholder
    input.value = value.slice(0, selectionStart) + before + selected + after + value.slice(selectionEnd)
    this.focusRange(selectionStart + before.length, selectionStart + before.length + selected.length)
    this.notify()
  }

  prefixLines(event, prefix) {
    event.preventDefault()
    const input = this.inputTarget
    const { selectionStart, selectionEnd, value } = input
    const lineStart = value.lastIndexOf("\n", selectionStart - 1) + 1
    const lineEnd = value.indexOf("\n", selectionEnd)
    const end = lineEnd === -1 ? value.length : lineEnd
    const prefixed = value.slice(lineStart, end).split("\n").map((line) => prefix + line).join("\n")
    input.value = value.slice(0, lineStart) + prefixed + value.slice(end)
    this.focusRange(lineStart, lineStart + prefixed.length)
    this.notify()
  }

  focusRange(start, end) {
    this.inputTarget.focus()
    this.inputTarget.setSelectionRange(start, end)
  }

  notify() {
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
