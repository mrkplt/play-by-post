# typed: true

module ApplicationCable
  # Identifies the connected user from the Warden session Devise already set up,
  # so a channel's `subscribed` can authorize a subscription against the same
  # identity the request pipeline uses. An unauthenticated socket connects with a
  # nil user rather than being rejected outright — the per-stream channels decide
  # what a nil user may subscribe to (public-game summaries can reach a guest;
  # anything narrower rejects).
  class Connection < ActionCable::Connection::Base
    extend T::Sig

    # `identified_by` defines `current_user` / `current_user=` at runtime; Sorbet
    # can't see that metaprogramming, so the setter is called through T.unsafe.
    # Channels read the identifier via #current_user (below), which is used within
    # this file by #connect too, so it is not a dead accessor.
    identified_by :current_user

    sig { void }
    def connect
      T.unsafe(self).current_user = find_verified_user
    end

    # The connected viewer, typed for channels that authorize against it (the
    # `identified_by` reader is untyped to Sorbet). Reads the same identifier
    # storage `identified_by`/its setter use.
    sig { returns(T.nilable(User)) }
    def current_user
      @current_user
    end

    private

    sig { returns(T.nilable(User)) }
    def find_verified_user
      env["warden"]&.user
    end
  end
end
