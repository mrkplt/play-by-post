FactoryBot.define do
  factory :private_key do
    # No `public_key` association — PublicKey lives in a different physical
    # database (see PrivateKey's class comment), so a factory-level
    # association can't span the connects_to boundary. This factory creates
    # a matching PublicKey by default so public_key_id always points at a
    # real row; pass public_key_id: explicitly to point at a specific one.
    transient do
      public_key_ref { create(:public_key) }
    end

    public_key_id { public_key_ref.id }
    encrypted_private_key { "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----" }
  end
end
