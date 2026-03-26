# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer_mailer/new_scene
  def new_scene
    NotificationMailer.new_scene
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer_mailer/scene_resolved
  def scene_resolved
    NotificationMailer.scene_resolved
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer_mailer/post_digest
  def post_digest
    NotificationMailer.post_digest
  end
end
