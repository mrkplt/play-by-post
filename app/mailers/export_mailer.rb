# typed: true

class ExportMailer < ApplicationMailer
  extend T::Sig

  sig { params(user: User, download_url: String, game: T.nilable(Game)).returns(Mail::Message) }
  def export_ready(user, download_url:, game: nil)
    @user = user
    @game = game
    @download_url = download_url
    @expires_days = 7

    subject = game ? "Your #{game.name} export is ready" : "Your export is ready"

    mail(to: user.email, subject: subject)
  end

  sig { params(user: User, game: T.nilable(Game)).returns(Mail::Message) }
  def export_failed(user, game: nil)
    @user = user
    @game = game

    subject = game ? "Your #{game.name} export failed" : "Your export failed"

    mail(to: user.email, subject: subject)
  end
end
