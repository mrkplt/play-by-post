# typed: false

module ApplicationCable
  # Identifies the connected user from the Warden session Devise already set up,
  # so a channel's `subscribed` can authorize a subscription against the same
  # identity the request pipeline uses. An unauthenticated socket connects with a
  # nil user rather than being rejected outright — the per-stream channels decide
  # what a nil user may subscribe to (public-game summaries can reach a guest;
  # anything narrower rejects).
  class Connection < ActionCable::Connection::Base
    extend T::Sig

    identified_by :current_user

    sig { void }
    def connect
      self.current_user = find_verified_user
    end

    private

    sig { returns(T.nilable(User)) }
    def find_verified_user
      env["warden"]&.user
    end
  end
end
