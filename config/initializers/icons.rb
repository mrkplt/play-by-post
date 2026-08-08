Icons.configure do |config|
  config.default_library = :hugeicons
end

# Configure Hugeicons to use currentColor for all fills/strokes
# This happens at sync time, not runtime
module Icons
  class Configuration
    module Hugeicons
      def transformations
        {
          svg: [
            { element: "path", action: :set_attribute, attribute: "fill", value: "currentColor" },
            { element: "path", action: :set_attribute, attribute: "stroke", value: "currentColor" },
            { element: "circle", action: :set_attribute, attribute: "fill", value: "currentColor" },
            { element: "circle", action: :set_attribute, attribute: "stroke", value: "currentColor" },
            { element: "rect", action: :set_attribute, attribute: "fill", value: "currentColor" },
            { element: "rect", action: :set_attribute, attribute: "stroke", value: "currentColor" },
            { element: "line", action: :set_attribute, attribute: "stroke", value: "currentColor" },
            { element: "polyline", action: :set_attribute, attribute: "stroke", value: "currentColor" },
            { element: "polygon", action: :set_attribute, attribute: "fill", value: "currentColor" },
            { element: "polygon", action: :set_attribute, attribute: "stroke", value: "currentColor" }
          ]
        }
      end
    end
  end
end
