require "rails_helper"

# The cable connection identifies the viewer from the same Warden session the
# request pipeline uses, so a channel can authorize against it. A socket with no
# authenticated Warden user still connects (nil user) — the per-stream channels
# decide what a guest may subscribe to.
RSpec.describe ApplicationCable::Connection, type: :channel do
  tests ApplicationCable::Connection

  it "identifies the Warden user when one is signed in" do
    user = create(:user, :with_profile)
    warden = instance_double(Warden::Proxy, user: user)

    connect env: { "warden" => warden }

    expect(connection.current_user).to eq(user)
  end

  it "connects with a nil user when no Warden user is present" do
    warden = instance_double(Warden::Proxy, user: nil)

    connect env: { "warden" => warden }

    expect(connection.current_user).to be_nil
  end

  it "connects with a nil user when Warden is absent entirely" do
    connect

    expect(connection.current_user).to be_nil
  end
end
