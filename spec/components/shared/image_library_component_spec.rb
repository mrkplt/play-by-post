require "rails_helper"

RSpec.describe Shared::ImageLibraryComponent, type: :component do
  def item(id:, current: false)
    {
      id: id,
      thumb_url: "/thumb/#{id}.jpg",
      display_url: "/display/#{id}.jpg",
      current: current,
      set_current_url: "/images/#{id}",
      delete_url: "/images/#{id}"
    }
  end

  def build_component(images:, can_manage:)
    described_class.new(
      title: "Portraits",
      images: images,
      can_manage: can_manage,
      empty_text: "No portraits yet."
    )
  end

  it "shows the empty text and no library items when there are no images" do
    render_inline(build_component(images: [], can_manage: true))

    expect(page).to have_text("No portraits yet.")
    expect(page).to have_no_css("[data-testid='library-item']")
  end

  it "renders the title" do
    render_inline(build_component(images: [], can_manage: true))
    expect(page).to have_text("Portraits")
  end

  it "renders the current image large and each library thumbnail" do
    render_inline(build_component(
      images: [ item(id: 1, current: true), item(id: 2) ],
      can_manage: true
    ))

    expect(page).to have_css("[data-testid='current-image']")
    expect(page).to have_css("[data-testid='library-item']", count: 2)
  end

  context "when the viewer can manage" do
    subject(:rendered) do
      render_inline(build_component(
        images: [ item(id: 1, current: true), item(id: 2) ],
        can_manage: true
      ))
    end

    it "offers no Use link — selection is by clicking the thumbnail" do
      expect(rendered).to have_no_css("[data-testid='use-image']")
    end

    it "offers Delete on every image" do
      expect(rendered).to have_css("[data-testid='delete-image']", count: 2)
    end

    it "offers a single Save control for the whole library" do
      expect(rendered).to have_css("[data-testid='save-image-selection']", count: 1)
    end

    it "makes every thumbnail a click target carrying its display URL and set-current URL" do
      expect(rendered).to have_css(
        "[data-testid='library-item'] img[data-image-select-target='thumb']", count: 2
      )
      expect(rendered).to have_css("img[data-image-select-display-url-param='/display/1.jpg']")
      expect(rendered).to have_css("img[data-image-select-set-current-url-param='/images/1']")
    end
  end

  context "when the viewer cannot manage" do
    subject(:rendered) do
      render_inline(build_component(
        images: [ item(id: 1, current: true) ],
        can_manage: false
      ))
    end

    it "shows no Use, Delete, or Save controls" do
      expect(rendered).to have_no_css("[data-testid='use-image']")
      expect(rendered).to have_no_css("[data-testid='delete-image']")
      expect(rendered).to have_no_css("[data-testid='save-image-selection']")
    end
  end

  context "when the library is empty" do
    it "shows no Save control" do
      render_inline(build_component(images: [], can_manage: true))
      expect(page).to have_no_css("[data-testid='save-image-selection']")
    end
  end

  describe "#current_image" do
    subject(:component) do
      build_component(
        images: [ item(id: 1, current: false), item(id: 2, current: true) ],
        can_manage: true
      )
    end

    # The current image is deliberately NOT first, so a mutant swapping find for
    # first (which would return id 1) is caught.
    it "returns the image whose current flag is set, not merely the first" do
      expect(component.current_image[:id]).to eq(2)
    end

    it "is nil when no image is current" do
      component = build_component(images: [ item(id: 1, current: false) ], can_manage: true)
      expect(component.current_image).to be_nil
    end
  end

  describe "#image_thumb_class" do
    subject(:component) { build_component(images: [], can_manage: true) }

    it "always includes the shared base classes" do
      expect(component.image_thumb_class(item(id: 1, current: false)))
        .to include("w-16", "h-16", "rounded-control", "object-cover")
    end

    it "rings the current image" do
      expect(component.image_thumb_class(item(id: 1, current: true)))
        .to include("ring-accent")
    end

    it "does not ring a non-current image" do
      expect(component.image_thumb_class(item(id: 2, current: false)))
        .not_to include("ring-accent")
    end
  end

  describe "#thumb_data" do
    it "carries the select action and every url/id/current param when the viewer can manage" do
      component = build_component(images: [], can_manage: true)

      data = component.thumb_data(item(id: 7, current: true))

      expect(data).to eq(
        image_select_target: "thumb",
        image_select_id_param: 7,
        action: "click->image-select#select",
        image_select_display_url_param: "/display/7.jpg",
        image_select_set_current_url_param: "/images/7",
        image_select_current_param: true
      )
    end

    it "carries only the target and id when the viewer cannot manage — no click action" do
      component = build_component(images: [], can_manage: false)

      data = component.thumb_data(item(id: 7))

      expect(data).to eq(image_select_target: "thumb", image_select_id_param: 7)
    end
  end
end
