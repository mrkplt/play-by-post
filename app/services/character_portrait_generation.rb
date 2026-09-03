# typed: true

# Fills in a pending portrait skeleton (a fileless CharacterImage the controller
# already created) by generating its image. The pipeline (plan §7):
#
#   1. compose the prompt (safety preamble + GM environment page + player text)
#   2. moderate the composed prompt (OpenAI Moderation via the rule pipeline);
#      a flagged verdict FAILS the skeleton before any key is spent
#   3. generate through the game pool (Ai::Funding + Ai::ImageRequest), failing
#      over across authorized keys
#   4. complete the skeleton (attach the image, stamp provenance) and write the
#      AiGeneration audit row
#
# On a moderation block or any generation failure the skeleton is marked failed
# with a player-facing reason (the character screen's frame-poll shows it, then
# cleans the row up). Nothing punitive — no lock.
class CharacterPortraitGeneration
  extend T::Sig

  FEATURE = "character_portrait"

  sig { params(image: CharacterImage, requested_by_id: Integer, player_prompt: String).void }
  def initialize(image, requested_by_id, player_prompt)
    @image = image
    @requested_by_id = requested_by_id
    @player_prompt = player_prompt
  end

  sig { void }
  def run
    return block if verdict.flagged?

    complete(generate)
  rescue Ai::ImageRequest::Refused, Ai::Funding::Exhausted, Faraday::Error => error
    fail_with("The portrait could not be generated. Please try again.", log: error.message)
  end

  private

  sig { returns(Ai::PortraitPrompt) }
  def prompt
    @prompt ||= Ai::PortraitPrompt.new(game: game, player_prompt: @player_prompt)
  end

  sig { returns(Ai::Moderation::Verdict) }
  def verdict
    @verdict ||= Ai::Moderation.new(api_key: moderation_key).call(prompt.to_s)
  end

  sig { returns(Ai::Funding::Spend) }
  def generate
    Ai::Funding.new(resolver: resolver, feature: FEATURE, game: game).call do |api_key|
      Ai::ImageRequest.new(model: image_model, prompt: prompt.to_s).call(api_key)
    end
  end

  # Complete the skeleton: attach the image + stamp provenance, and record the
  # permanent AiGeneration audit row (who requested it, whose pooled key paid),
  # atomically. Not made current — the player chooses (no auto-publish).
  sig { params(spend: Ai::Funding::Spend).void }
  def complete(spend)
    ActiveRecord::Base.transaction do
      @image.complete_generation!(png_attachable(spend.value.png_bytes))
      record_generation(spend)
    end
  end

  sig { params(png_bytes: String).returns(T::Hash[Symbol, T.untyped]) }
  def png_attachable(png_bytes)
    { io: StringIO.new(png_bytes), filename: "portrait.png", content_type: "image/png" }
  end

  sig { params(spend: Ai::Funding::Spend).void }
  def record_generation(spend)
    AiGeneration.create!(
      feature: FEATURE, model_used: image_model, cost: spend.value.cost,
      requested_by_id: @requested_by_id, funded_by_id: spend.funded_by.id,
      asset_type: "CharacterImage", asset_id: @image.id
    )
  end

  sig { void }
  def block
    Rails.logger.warn(
      "CharacterPortraitGeneration blocked character=#{@image.character_id} " \
      "reasons=#{verdict.reasons.join('; ')} " \
      "game_prompt=#{prompt.game_part.inspect} player_prompt=#{@player_prompt.inspect}"
    )
    @image.fail_generation!("That prompt was blocked by content moderation. Please try a different description.")
  end

  sig { params(reason: String, log: String).void }
  def fail_with(reason, log:)
    Rails.logger.error("CharacterPortraitGeneration failed character=#{@image.character_id}: #{log}")
    @image.fail_generation!(reason)
  end

  sig { returns(Game) }
  def game
    T.must(character.game)
  end

  sig { returns(Character) }
  def character
    T.must(@image.character)
  end

  sig { returns(AiKeyResolver) }
  def resolver
    AiKeyResolver.new(key_source: Crypto::StoredKeySource.new)
  end

  # The OpenAI key for the moderation pre-screen (Ai::Moderation calls OpenAI's
  # /v1/moderations, NOT OpenRouter — a distinct credential). Nested under
  # `openai:` in the encrypted credentials.
  sig { returns(String) }
  def moderation_key
    Rails.application.credentials.openai.api_key.to_s
  end

  # The image model is required operational config — no default, so a missing
  # OPENROUTER_IMAGE_MODEL fails loudly (KeyError) rather than generating with a
  # stale model.
  sig { returns(String) }
  def image_model
    ENV.fetch("OPENROUTER_IMAGE_MODEL")
  end
end
