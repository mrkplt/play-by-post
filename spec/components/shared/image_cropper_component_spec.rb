require "rails_helper"

RSpec.describe Shared::ImageCropperComponent, type: :component do
  subject(:rendered) do
    render_inline(described_class.new(upload_url: "/profile/images", title: "Add an avatar", add_label: "Add avatar"))
  end

  it "wires the image-cropper Stimulus controller with the upload URL" do
    expect(rendered).to have_css("[data-controller='image-cropper'][data-image-cropper-upload-url-value='/profile/images']")
  end

  it "renders the title" do
    expect(rendered).to have_text("Add an avatar")
  end

  it "renders the add-image trigger inside the controller scope" do
    expect(rendered).to have_css("[data-controller='image-cropper'] [data-testid='add-image'][data-action='image-cropper#open']", text: "Add avatar")
  end

  it "renders a hidden modal, a file input, and a disabled save button" do
    expect(rendered).to have_css("[data-image-cropper-target='modal'].hidden")
    expect(rendered).to have_css("input[type='file'][data-image-cropper-target='fileInput']")
    expect(rendered).to have_css("[data-testid='crop-save'][disabled]")
  end

  it "renders all four crop controls with their action, label, and symbol" do
    controls = {
      "image-cropper#zoomIn" => [ "Zoom in", "+" ],
      "image-cropper#zoomOut" => [ "Zoom out", "−" ],
      "image-cropper#rotateLeft" => [ "Rotate left", "↺" ],
      "image-cropper#rotateRight" => [ "Rotate right", "↻" ]
    }

    controls.each do |action, (label, symbol)|
      button = rendered.at_css("button[data-action='#{action}']")
      expect(button).to be_present, "missing control for #{action}"
      expect(button["aria-label"]).to eq(label)
      expect(button.text.strip).to eq(symbol)
    end
  end

  it "gives every control button the shared control-button class" do
    buttons = rendered.css("[data-image-cropper-target='cropArea'] button")
    expect(buttons.size).to eq(4)
    buttons.each do |button|
      expect(button["class"]).to eq(described_class::CONTROL_BUTTON_CLASS)
    end
  end
end
