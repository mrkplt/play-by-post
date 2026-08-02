# typed: strict

# Bordered card shell — the shared visual container that groups
# SettingsRowComponent rows (or similar content) under a section label.
class Ui::CardComponent < ApplicationComponent
  extend T::Sig

  BASE = T.let("bg-card border border-card-border rounded-card px-3.5", String)

  sig { returns(String) }
  def classes
    BASE
  end
end
