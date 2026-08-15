# typed: true

module GameExport
  # How a person is named throughout an export: their display name, falling
  # back to the email when they have not set one. Every document that credits a
  # user — members, participants, post authors, sheet owners, version editors —
  # goes through here so one person reads the same way everywhere.
  module Author
    extend T::Sig

    sig { params(user: T.untyped).returns(String) }
    def self.name_for(user)
      present = T.must(user)
      present.display_name.presence || present.email
    end
  end
end
