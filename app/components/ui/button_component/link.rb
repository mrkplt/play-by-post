# typed: strict

# The button's link-path configuration. When `url` is present the component
# renders a Rails `link_to` styled as a button instead of a plain <button>,
# with `method`/`confirm` passed through as `data-turbo-method` /
# `data-turbo-confirm`. Extra `data:` is merged in, caller keys winning on
# conflict. Grouping these four keeps Ui::ButtonComponent's own parameter
# list to this bundle plus the separate Style concern (see
# button_component/style.rb).
class Ui::ButtonComponent::Link < T::Struct
  extend T::Sig

  const :url, T.nilable(String), default: nil
  # `method` collides with Kernel#method, so this prop skips the generated
  # accessor and #http_method below reads the ivar directly instead.
  const :method, T.nilable(Symbol), default: nil, without_accessors: true
  const :confirm, T.nilable(String), default: nil
  const :data, T::Hash[Symbol, T.untyped], default: {}

  sig { returns(T::Boolean) }
  def present?
    url.present?
  end

  sig { returns(T.nilable(Symbol)) }
  def http_method
    @method
  end

  # The link's data hash — carries turbo_method/turbo_confirm only when the
  # caller asked for one, keeping the component free of inline logic.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def data_attributes
    attrs = data.dup
    attrs[:turbo_method] = http_method if http_method
    attrs[:turbo_confirm] = confirm if confirm
    attrs
  end
end
