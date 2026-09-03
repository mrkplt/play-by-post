# typed: true
# frozen_string_literal: true

require "faraday"

module Ai
  # Builds the Faraday connection the AI HTTP services share: bearer auth, JSON
  # request/response, raise-on-error, timeouts, and an injectable adapter (so
  # specs drive the real middleware stack through Faraday's test adapter). Split
  # out so the one reek-hostile builder block (the `f` config) lives in a single
  # place instead of being repeated in every service.
  module HttpConnection
    extend T::Sig

    # `adapter` is a Faraday adapter (a Symbol, or [:test, stubs] in specs),
    # splatted into f.adapter so both shapes work.
    sig { params(api_key: String, timeout: Integer, adapter: T.untyped).returns(T.untyped) }
    def self.build(api_key:, timeout:, adapter:)
      T.unsafe(Faraday).new do |conn|
        configure(conn, api_key, timeout)
        conn.adapter(*Array(adapter))
      end
    end

    sig { params(conn: T.untyped, api_key: String, timeout: Integer).void }
    def self.configure(conn, api_key, timeout)
      add_middleware(conn, api_key)
      set_timeouts(conn.options, timeout)
    end
    private_class_method :configure

    sig { params(conn: T.untyped, api_key: String).void }
    def self.add_middleware(conn, api_key)
      conn.request :authorization, "Bearer", api_key
      conn.response :json
      conn.response :raise_error
    end
    private_class_method :add_middleware

    sig { params(options: T.untyped, timeout: Integer).void }
    def self.set_timeouts(options, timeout)
      options.timeout = timeout
      options.open_timeout = 10
    end
    private_class_method :set_timeouts
  end
end
