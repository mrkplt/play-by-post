# typed: strict

module AiKeypairs
  # Raised for any failure decrypting a browser-produced BYOK key envelope:
  # malformed JSON/base64, a missing field, or a failed GCM authentication
  # check (tampered ciphertext, wrong key, wrong IV). Deliberately one error
  # class for all of these — see CryptoService#decrypt for why collapsing
  # them matters on this path.
  class DecryptionError < StandardError; end
end
