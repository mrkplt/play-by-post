# typed: true

# URI::MailTo::EMAIL_REGEXP is defined in Ruby's stdlib but missing from the
# generated RBI for the uri gem. Added here so Sorbet can resolve it.
class URI::MailTo
  EMAIL_REGEXP = T.let(T.unsafe(nil), Regexp)
end
