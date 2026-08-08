Icons.configure do |config|
  config.default_library = :hugeicons
end

# Monkey-patch Hugeicons to add SVG transformations
# This converts all fill/stroke colors to currentColor at sync time
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
