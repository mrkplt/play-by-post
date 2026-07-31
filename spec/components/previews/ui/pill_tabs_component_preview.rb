# @label Pill Tabs
class Ui::PillTabsComponentPreview < ViewComponent::Preview
  def default
    tabs = [
      Ui::PillTabsComponent::Tab.new(label: "Scenes", href: "#"),
      Ui::PillTabsComponent::Tab.new(label: "Roster", href: "#"),
      Ui::PillTabsComponent::Tab.new(label: "Files", href: "#")
    ]
    render(Ui::PillTabsComponent.new(tabs: tabs, active: :scenes))
  end
end
