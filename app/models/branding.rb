# typed: strict

# Per-deployment brand identity: the display name and canonical URL a running
# instance calls itself. The open-source project is "Play by Post"; a given
# deployment overrides both via env (this instance is flailwhale.com). Every
# user-facing surface — layout title, sidebar wordmark, invitation emails, the
# PWA manifest, and the API docs — reads its name here rather than hardcoding a
# string, so rebranding an instance is a matter of setting two env vars.
#
#   APP_NAME  the human display name (default "Play by Post"). May contain
#             spaces ("Flail Whale") — it is *only* ever rendered as text and is
#             never used to build a URL.
#   APP_HOST  the host, reused from the mailer-link setting. The URL is
#             https://<host> (default "play-by-post.example.com"). #url derives
#             from APP_HOST alone, never from APP_NAME.
#
# A pure, memo-free reader so tests can stub ENV per-example without a
# cached value leaking across them. Named #display_name rather than #name so it
# never shadows Module#name, which Rails autoloading and Sorbet call on the
# constant itself.
module Branding
  extend T::Sig

  DEFAULT_NAME = T.let("Play by Post", String)
  DEFAULT_HOST = T.let("play-by-post.example.com", String)

  sig { returns(String) }
  def self.display_name
    ENV.fetch("APP_NAME", DEFAULT_NAME)
  end

  sig { returns(String) }
  def self.host
    ENV.fetch("APP_HOST", DEFAULT_HOST)
  end

  sig { returns(String) }
  def self.url
    "https://#{host}"
  end
end
