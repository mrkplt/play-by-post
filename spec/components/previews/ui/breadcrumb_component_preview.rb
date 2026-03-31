# @label Breadcrumb
class Ui::BreadcrumbComponentPreview < ViewComponent::Preview
  def default
    render(Ui::BreadcrumbComponent.new) { "Games &rsaquo; My Game &rsaquo; Scene".html_safe }
  end
end
