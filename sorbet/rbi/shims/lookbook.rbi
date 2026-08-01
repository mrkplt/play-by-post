# typed: false

# Minimal shim so config/routes.rb (typed: true) can reference Lookbook::Engine
# when mounting the dev-only component gallery. The full lookbook gem RBI pulls
# in unresolved Rouge/YARD constants, so we declare only what we use.
module Lookbook
  class Engine < ::Rails::Engine; end
end
