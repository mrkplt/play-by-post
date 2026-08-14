RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  # A templateless component (one that renders from `def call` rather than a
  # sibling .html.erb) is compiled by copying `call` into a generated
  # `_call_<name>` method, which is what `render_template_for` actually
  # dispatches to. The copy is taken once, at compile time.
  #
  # The test env eager-loads (config/environments/test.rb), so that copy is
  # taken during boot. Anything that redefines `call` afterwards is then
  # invisible to rendering, because the stale copy is what runs. Mutant does
  # exactly that: it rewrites `call` per mutation, the component keeps rendering
  # the original, and every mutation of `call` (plus every private method
  # reachable only from it) survives — a coverage collapse with a green suite.
  #
  # Recompiling before each example re-takes the copy from whatever `call` is
  # currently defined, so rendering reflects the live method. Only templateless
  # components need it — ones with a template compile their ERB, not `call`.
  # `InlineCall` is the template class ViewComponent uses for exactly these
  # components; a template-backed one compiles its ERB instead and is unaffected.
  inline_call_components = lambda do
    ViewComponent::Base.descendants.select do |component|
      component.__vc_compiler.send(:templates).any? { |t| t.is_a?(ViewComponent::Template::InlineCall) }
    rescue StandardError
      false
    end
  end

  config.before(:each) do
    inline_call_components.call.each { |component| component.__vc_compile(force: true) }
  end
end
