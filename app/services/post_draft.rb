# typed: strict
# frozen_string_literal: true

# Drafts are per (scene, user): saving updates in place and publishing
# promotes the same record, so a user never ends up with two.
class PostDraft
  extend T::Sig

  sig { params(scene: Scene, user: User).void }
  def initialize(scene, user)
    @scene = scene
    @user = user
  end

  sig { returns(T.nilable(Post)) }
  def find
    @scene.posts.drafts.find_by(user: @user)
  end

  class Result < T::Struct
    const :saved, T::Boolean
    const :draft, Post
  end

  # `is_ooc` is a raw param: nil from an unchecked box, "0"/"false" from an
  # explicit off, so it is cast the way the column would cast it.
  sig { params(content: T.untyped, is_ooc: T.untyped).returns(Result) }
  def save(content:, is_ooc:)
    draft = @scene.posts.drafts.find_or_initialize_by(user: @user)
    draft.assign_attributes(content: content, is_ooc: ooc_flag(is_ooc), draft: true)

    Result.new(saved: draft.save, draft: draft)
  end

  sig { void }
  def discard
    find&.destroy
  end

  sig { params(attributes: T.untyped).returns(Post) }
  def publish_target(attributes)
    existing = find
    return promote(existing, attributes) if existing

    T.cast(@scene.posts.new(attributes), Post).tap { |post| post.user = @user }
  end

  private

  sig { params(value: T.untyped).returns(T::Boolean) }
  def ooc_flag(value)
    ActiveModel::Type::Boolean.new.cast(value).present?
  end

  sig { params(draft: Post, attributes: T.untyped).returns(Post) }
  def promote(draft, attributes)
    draft.tap { |record| record.assign_attributes(attributes.merge(draft: false, last_edited_at: nil)) }
  end
end
