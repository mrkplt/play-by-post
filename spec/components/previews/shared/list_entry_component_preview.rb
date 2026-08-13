# @label List Entry
class Shared::ListEntryComponentPreview < ViewComponent::Preview
  def default
    render(Shared::ListEntryComponent.new(
      rows: [
        { title: "The Sunken Temple", href: "#", controls: nil },
        { title: "Harbour Districts", href: "#", controls: nil },
        { title: "A very long entry title that runs past the width of the row and truncates", href: "#", controls: nil }
      ],
      empty_text: "Nothing here yet."))
  end

  def with_controls
    render(Shared::ListEntryComponent.new(
      rows: [
        { title: "The Sunken Temple", href: "#", controls: Ui::BadgeComponent.new(variant: :green) },
        { title: "Harbour Districts", href: "#", controls: Ui::BadgeComponent.new(variant: :yellow) }
      ],
      empty_text: "Nothing here yet."))
  end

  def mixed_controls
    render(Shared::ListEntryComponent.new(
      rows: [
        { title: "With controls", href: "#", controls: Ui::BadgeComponent.new(variant: :blue) },
        { title: "Without controls", href: "#", controls: nil }
      ],
      empty_text: "Nothing here yet."))
  end

  def empty
    render(Shared::ListEntryComponent.new(rows: [], empty_text: "No pages yet."))
  end
end
