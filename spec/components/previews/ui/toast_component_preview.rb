# @label Toast
class Ui::ToastComponentPreview < ViewComponent::Preview
  # A success toast holds solid for 2s, then fades over 3s and removes itself.
  # @label Success (auto-dismisses)
  def success
    render(Ui::ToastComponent.new(toasts: [ { message: "Entry moved.", variant: :success } ]))
  end

  # Errors persist with a dismiss button — a missed error is worse than a
  # banner left standing.
  # @label Error (persists)
  def error
    render(Ui::ToastComponent.new(toasts: [ { message: "Could not create post.", variant: :error } ]))
  end

  # When a write sets both, the error stacks first: it is the message still
  # worth reading after the success toast has faded.
  # @label Both
  def both
    render(Ui::ToastComponent.new(toasts: [
      { message: "Could not create post.", variant: :error },
      { message: "Draft saved.", variant: :success }
    ]))
  end
end
