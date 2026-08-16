# typed: strict
# frozen_string_literal: true

# Assembles a minimal RFC 2822 MIME message from the Resend email object
# returned by +Resend::Emails::Receiving.get+. Extracted from
# ActionMailbox::Ingresses::Resend::InboundEmailsController: constructing the
# Mail object is data-shaping logic that belongs with the data it builds from,
# not with the controller that receives the webhook.
class InboundMailBuilder
  extend T::Sig

  sig { params(data: T::Hash[T.untyped, T.untyped]).returns(String) }
  def self.call(data)
    new(data).call
  end

  sig { params(data: T::Hash[T.untyped, T.untyped]).void }
  def initialize(data)
    @data = data
  end

  sig { returns(String) }
  def call
    mail = Mail.new
    assign_headers(mail)
    assign_body(mail)
    mail.to_s
  end

  private

  sig { params(mail: Mail::Message).void }
  def assign_headers(mail)
    mail.from    = @data["from"].to_s
    mail.to      = Array(@data["to"]).join(", ")
    mail.subject = @data["subject"].to_s
  end

  sig { params(mail: Mail::Message).void }
  def assign_body(mail)
    html_body = @data["html"]
    text_body = @data["text"]

    if html_body && text_body
      assign_multipart_body(mail, html_body: html_body, text_body: text_body)
    elsif html_body
      assign_html_only_body(mail, html_body)
    else
      mail.body = text_body.to_s
    end
  end

  sig { params(mail: Mail::Message, html_body: String).void }
  def assign_html_only_body(mail, html_body)
    mail.content_type = "text/html; charset=UTF-8"
    mail.body = html_body
  end

  sig { params(mail: Mail::Message, html_body: String, text_body: String).void }
  def assign_multipart_body(mail, html_body:, text_body:)
    mail.text_part = build_text_part(text_body)
    mail.html_part = build_html_part(html_body)
  end

  sig { params(text_body: String).returns(Mail::Part) }
  def build_text_part(text_body)
    Mail::Part.new.tap { |part| part.body = text_body }
  end

  sig { params(html_body: String).returns(Mail::Part) }
  def build_html_part(html_body)
    Mail::Part.new.tap do |part|
      part.content_type = "text/html; charset=UTF-8"
      part.body = html_body
    end
  end
end
