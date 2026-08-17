# typed: true
# frozen_string_literal: true

# Inline styles for mailer views, composed from the Palette single source of
# truth. Mail clients cannot use the compiled Tailwind stylesheet, so emails
# must inline their colours — these helpers keep the hex out of the ERB (which
# may hold no raw colour and no logic) and give each style a semantic name.
module MailStylesHelper
  extend T::Sig

  # Muted meta text (author line, footers, expiry notes). `size` picks the
  # font-size used across the mailers; extra declarations append verbatim.
  sig { params(size: T.nilable(String), extra: T.nilable(String)).returns(String) }
  def mail_meta_style(size: nil, extra: nil)
    parts = [ "color:#{Palette[:mail_meta]}" ]
    parts << "font-size:#{size}" if size
    parts << extra if extra
    parts.join("; ")
  end

  # Left border rule on a digest post block.
  sig { returns(String) }
  def mail_rule_style
    "border-left:3px solid #{Palette[:mail_rule]}; padding-left:1rem; margin-bottom:1rem;"
  end

  # Primary call-to-action button.
  sig { returns(String) }
  def mail_button_style
    "background:#{Palette[:mail_action]}; color:white; padding:0.625rem 1.25rem; " \
      "border-radius:0.375rem; text-decoration:none; font-weight:600;"
  end
end
