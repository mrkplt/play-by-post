# typed: strict
# frozen_string_literal: true

# Assembles the Turbo Streams (and the control component) that
# Profiles::ByokKeysController answers with — the BYOK lifecycle happens fully
# in place, so every action renders one of these assemblies rather than
# redirecting:
#
#   - #creation: the control (pending unless the keypair already exists) plus
#     the outcome toast — #create's response.
#   - #settled: the control in its persisted state, the profile's "Your Games"
#     control-plane section (whose funding rows follow key presence), and the
#     toast — seal and delete's shared response.
#   - #component: the bare control for #show, the pending poll's target.
#
# The control state always comes from UserByokKeyPresenter — the same source
# profiles#show renders from — so a stream can never disagree with a cold page
# load. The flash rides flash.now into the toast swap.
class ByokKeyStreams
  extend T::Sig

  # The controller's view machinery, handed over as one bundle rather than
  # this class reaching for request state (R2-style boundary).
  class Context < T::Struct
    const :turbo_stream, T.untyped
    const :helpers, T.untyped
    const :flash, T.untyped
  end

  sig { params(user: User, context: Context, endpoint_url: String).void }
  def initialize(user:, context:, endpoint_url:)
    @user = user
    @context = context
    @endpoint_url = endpoint_url
  end

  sig { params(pending: T::Boolean).returns(T::Array[String]) }
  def creation(pending:)
    [ control(pending: pending), toast ]
  end

  sig { returns(T::Array[String]) }
  def settled
    [ control(pending: false), game_controls, toast ]
  end

  sig { params(pending: T::Boolean).returns(Ui::ByokKeyFormComponent) }
  def component(pending:)
    presenter = UserByokKeyPresenter.new(@user)
    Ui::ByokKeyFormComponent.new(
      key_present: presenter.present?,
      public_key_pem: presenter.public_key_pem,
      endpoint_url: @endpoint_url,
      pending: pending
    )
  end

  private

  sig { params(pending: T::Boolean).returns(String) }
  def control(pending:)
    @context.turbo_stream.replace(Ui::ByokKeyFormComponent::FRAME_ID, component(pending: pending))
  end

  sig { returns(String) }
  def game_controls
    @context.turbo_stream.replace(
      "game_controls",
      partial: "profiles/game_controls",
      locals: { user_presenter: UserPresenter.new(@user, helpers: @context.helpers) }
    )
  end

  sig { returns(String) }
  def toast
    @context.turbo_stream.replace("toast_layer", Ui::ToastComponent.new(toasts: FlashPresenter.new(@context.flash).toasts))
  end
end
