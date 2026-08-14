# typed: strict

class ExportMailer < ApplicationMailer
  extend T::Sig

  sig { params(user: User, download_url: String, game: T.nilable(Game)).returns(Mail::Message) }
  def export_ready(user, download_url:, game: nil)
    @export = T.let(
      ExportDeliveryPresenter.new(
        UserPresenter.new(user),
        game: game && GamePresenter.new(game),
        download_url: download_url,
        expires_days: 7
      ),
      T.nilable(ExportDeliveryPresenter)
    )

    subject = game ? "Your #{game.name} export is ready" : "Your export is ready"

    mail(to: user.email, subject: subject)
  end

  sig { params(user: User, game: T.nilable(Game)).returns(Mail::Message) }
  def export_failed(user, game: nil)
    @export = T.let(
      ExportDeliveryPresenter.new(UserPresenter.new(user), game: game && GamePresenter.new(game)),
      T.nilable(ExportDeliveryPresenter)
    )

    subject = game ? "Your #{game.name} export failed" : "Your export failed"

    mail(to: user.email, subject: subject)
  end
end
