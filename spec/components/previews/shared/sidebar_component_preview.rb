# @label Sidebar
class Shared::SidebarComponentPreview < ViewComponent::Preview
  def signed_out
    render(Shared::SidebarComponent.new(current_user: nil))
  end

  def signed_in
    user = User.first || User.new(email: "player@example.com")
    render(Shared::SidebarComponent.new(current_user: user))
  end
end
