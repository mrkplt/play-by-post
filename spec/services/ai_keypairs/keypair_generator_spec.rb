require "rails_helper"

RSpec.describe AiKeypairs::KeypairGenerator do
  describe ".call" do
    it "returns a PEM-encoded RSA-2048 public/private keypair" do
      generated = described_class.call

      public_key = OpenSSL::PKey::RSA.new(generated.public_key_pem)
      private_key = OpenSSL::PKey::RSA.new(generated.private_key_pem)

      expect(public_key.public?).to be(true)
      expect(private_key.private?).to be(true)
      expect(private_key.n).to eq(public_key.n)
      expect(private_key.n.num_bits).to eq(described_class::RSA_KEY_BITS)
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
