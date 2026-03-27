# typed: true

class ActiveStorage::Attached::One
  sig { returns(T.nilable(String)) }
  def content_type; end

  sig { returns(T.nilable(Integer)) }
  def byte_size; end

  sig { params(transformations: T.untyped).returns(ActiveStorage::VariantWithRecord) }
  def variant(**transformations); end

  sig { params(transformations: T.untyped).returns(ActiveStorage::Preview) }
  def preview(**transformations); end

  sig { returns(T::Boolean) }
  def previewable?; end
end

class ActiveStorage::VariantWithRecord
end

class ActiveStorage::Preview
end
