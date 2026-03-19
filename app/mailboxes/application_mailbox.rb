class ApplicationMailbox < ActionMailbox::Base
  routing(/\Ascene-\d+@/i => :scene)
end
