# typed: strict

# The resolved-scene outcome card shown on the scene screen: the GM's resolution
# text rendered as markdown (single newlines become line breaks). The caller
# gates rendering on the scene being resolved with a present resolution.
class Shared::SceneResolutionComponent < ApplicationComponent
  extend T::Sig

  sig { params(resolution: String).void }
  def initialize(resolution:)
    @resolution = T.let(resolution, String)
  end
end
