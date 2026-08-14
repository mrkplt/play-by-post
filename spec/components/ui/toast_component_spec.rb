require "rails_helper"

RSpec.describe Ui::ToastComponent, type: :component do
  def toast(message: "Saved.", variant: :success)
    { message: message, variant: variant }
  end

  it "renders nothing when there are no toasts" do
    render_inline(described_class.new)
    expect(page).not_to have_css(".toast-layer")
  end

  it "renders nothing when handed an empty array" do
    render_inline(described_class.new(toasts: []))
    expect(page).not_to have_css(".toast-layer")
  end

  describe "variants" do
    described_class::VARIANT_CLASSES.each do |variant, classes|
      it "renders the #{variant} variant with its own modifier class" do
        render_inline(described_class.new(toasts: [ toast(message: "Hi.", variant: variant) ]))

        expect(page).to have_css(".#{classes.split.last}", text: "Hi.")
      end
    end
  end

  it "renders one toast per entry" do
    render_inline(described_class.new(toasts: [
      toast(message: "Saved.", variant: :success),
      toast(message: "Broke.", variant: :error)
    ]))

    expect(page).to have_css("[data-testid='toast']", count: 2)
    expect(page).to have_text("Saved.")
    expect(page).to have_text("Broke.")
  end

  # The layer being out of flow is the whole point of the component — a
  # regression to a flow element is what pushed the app header down 64px and
  # made notices read as "nothing happened".
  it "wraps toasts in the fixed overlay layer" do
    render_inline(described_class.new(toasts: [ toast ]))

    expect(page).to have_css(".toast-layer .toast")
  end

  describe "auto-dismiss" do
    it "attaches the toast controller to a success toast and arms it" do
      render_inline(described_class.new(toasts: [ toast(variant: :success) ]))

      expect(page).to have_css("[data-controller='toast'][data-toast-auto-dismiss-value='true']")
    end

    it "attaches the controller to an error toast but does not arm it" do
      render_inline(described_class.new(toasts: [ toast(variant: :error) ]))

      expect(page).to have_css("[data-controller='toast'][data-toast-auto-dismiss-value='false']")
    end
  end

  describe "dismiss button" do
    it "gives a persistent error toast a way out" do
      render_inline(described_class.new(toasts: [ toast(variant: :error) ]))

      expect(page).to have_css("button.toast__dismiss[aria-label='Dismiss'][data-action='click->toast#dismiss']")
    end

    it "omits the button on a toast that dismisses itself" do
      render_inline(described_class.new(toasts: [ toast(variant: :success) ]))

      expect(page).not_to have_css("button.toast__dismiss")
    end
  end

  describe "#any?" do
    it "is false with no toasts" do
      expect(described_class.new.any?).to be false
    end

    it "is true with a toast" do
      expect(described_class.new(toasts: [ toast ]).any?).to be true
    end
  end

  describe "#self_dismissing?" do
    it "is true for a success toast" do
      expect(described_class.new.self_dismissing?(toast(variant: :success))).to be true
    end

    it "is false for an error toast" do
      expect(described_class.new.self_dismissing?(toast(variant: :error))).to be false
    end

    it "decides on the variant, not the message" do
      expect(described_class.new.self_dismissing?({ message: "success", variant: :error })).to be false
    end
  end

  describe "#dismissible?" do
    it "is true for an error toast" do
      expect(described_class.new.dismissible?(toast(variant: :error))).to be true
    end

    it "is false for a success toast" do
      expect(described_class.new.dismissible?(toast(variant: :success))).to be false
    end
  end

  describe "#classes_for" do
    it "looks the classes up by the toast's variant" do
      component = described_class.new

      expect(component.classes_for(toast(variant: :success)))
        .to eq(described_class::VARIANT_CLASSES.fetch(:success))
      expect(component.classes_for(toast(variant: :error)))
        .to eq(described_class::VARIANT_CLASSES.fetch(:error))
    end

    it "reads the variant rather than any other key on the toast" do
      classes = described_class.new.classes_for({ message: "error", variant: :success })

      expect(classes).to eq(described_class::VARIANT_CLASSES.fetch(:success))
    end

    it "raises on an unknown variant rather than rendering an unstyled chip" do
      expect { described_class.new.classes_for(toast(variant: :nope)) }.to raise_error(KeyError)
    end
  end
end
