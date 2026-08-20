FactoryBot.define do
  factory :ai_private_key do
    # No `ai_keypair` association — AiKeypair lives in a different physical
    # database (see AiPrivateKey's class comment), so a factory-level
    # association can't span the connects_to boundary. This factory creates
    # a matching AiKeypair by default so ai_keypair_id always points at a
    # real row; pass ai_keypair_id: explicitly to point at a specific one.
    transient do
      ai_keypair_ref { create(:ai_keypair) }
    end

    ai_keypair_id { ai_keypair_ref.id }
    encrypted_private_key { "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----" }
  end
end
