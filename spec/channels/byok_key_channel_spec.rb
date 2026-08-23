require "rails_helper"

# Subscription authorization: a user may subscribe only to their OWN keypair
# stream. The signed stream name stops a client inventing a stream; this channel
# additionally rejects a valid signed name for a different owner.
RSpec.describe ByokKeyChannel, type: :channel do
  let(:user) { create(:user, :with_profile) }
  let(:other) { create(:user, :with_profile) }

  def signed(owner)
    Turbo::StreamsChannel.signed_stream_name([ owner, :byok_keypair ])
  end

  def subscribe_to(owner)
    subscribe(signed_stream_name: signed(owner))
  end

  it "accepts a user subscribing to their own keypair stream", :db do
    stub_connection(current_user: user)
    subscribe_to(user)

    expect(subscription).to be_confirmed
    # Streams from the verified (unsigned) name, the same form broadcasts target.
    expect(subscription).to have_stream_from(Turbo::StreamsChannel.verified_stream_name(signed(user)))
  end

  it "rejects a user replaying another owner's keypair stream name", :db do
    stub_connection(current_user: user)
    subscribe_to(other)

    expect(subscription).to be_rejected
  end

  it "rejects an unauthenticated socket", :db do
    stub_connection(current_user: nil)
    subscribe_to(user)

    expect(subscription).to be_rejected
  end
end
