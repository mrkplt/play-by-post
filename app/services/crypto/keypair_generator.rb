# typed: strict

module Crypto
  # Generates a fresh RSA-2048 custody keypair (public half stored in
  # PublicKey, private half in PrivateKey — see CryptoService's class comment
  # for the full custody model and envelope format the public key is used
  # with). A stateless process, so a module with module methods rather than
  # an instantiated class (bin/check-service-modules).
  module KeypairGenerator
    extend T::Sig

    RSA_KEY_BITS = 2048

    # Result of .call: the PEM key material for a fresh PublicKey/PrivateKey
    # pair, not yet persisted. Kept as a plain struct rather than persisting
    # inside this class, so the caller controls the transaction (both rows
    # are written together, see PublicKey/PrivateKey).
    class GeneratedKeypair < T::Struct
      const :public_key_pem, String
      const :private_key_pem, String
      const :fingerprint, String
    end

    sig { returns(GeneratedKeypair) }
    def self.call
      rsa_key = OpenSSL::PKey::RSA.new(RSA_KEY_BITS)

      GeneratedKeypair.new(
        # #public_key.to_pem / #to_pem (not #public_to_pem / #private_to_pem):
        # equivalent output, but covered by Sorbet's bundled openssl RBI,
        # which lags the gem's newer `_to_pem`/`_to_der` method names.
        public_key_pem: rsa_key.public_key.to_pem,
        private_key_pem: rsa_key.to_pem,
        fingerprint: fingerprint_for(rsa_key)
      )
    end

    sig { params(rsa_key: OpenSSL::PKey::RSA).returns(String) }
    def self.fingerprint_for(rsa_key)
      OpenSSL::Digest::SHA256.hexdigest(rsa_key.public_key.to_der)
    end
  end
end
