require "rails_helper"

RSpec.describe AiKeypairs::KeypairGenerator do
  describe ".call" do
    it "returns a PEM-encoded RSA-2048 public/private keypair" do
      generated = described_class.call

      public_key = OpenSSL::PKey::RSA.new(generated.public_key_pem)
      private_key = OpenSSL::PKey::RSA.new(generated.private_key_pem)

      expect(public_key.public?).to be(true)
      # public_key_pem must hold ONLY the public half — a private key object
      # is also #public? true, so this is the assertion that actually
      # distinguishes "public_key.to_pem" from "rsa_key.to_pem" (the whole
      # keypair, private material included).
      expect(public_key.private?).to be(false)
      expect(private_key.private?).to be(true)
      expect(private_key.n).to eq(public_key.n)
      expect(private_key.n.num_bits).to eq(described_class::RSA_KEY_BITS)
    end

    it "does not leak private key material into public_key_pem" do
      generated = described_class.call

      expect(generated.public_key_pem).not_to include("PRIVATE KEY")
    end

    it "returns a fingerprint that is the SHA-256 hex digest of the public key DER" do
      generated = described_class.call
      public_key = OpenSSL::PKey::RSA.new(generated.public_key_pem)

      expect(generated.fingerprint).to eq(OpenSSL::Digest::SHA256.hexdigest(public_key.public_key.to_der))
    end

    it "generates a fresh keypair on every call" do
      first = described_class.call
      second = described_class.call

      expect(first.fingerprint).not_to eq(second.fingerprint)
    end
  end
end
