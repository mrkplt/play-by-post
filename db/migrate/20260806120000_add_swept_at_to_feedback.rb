class AddSweptAtToFeedback < ActiveRecord::Migration[8.1]
  def change
    # Set when the entry has been imported into the Fizzy board (see
    # FizzySweepService / FeedbackSweepJob). NULL means "not yet swept".
    add_column :feedback, :swept_at, :datetime
    add_index :feedback, :swept_at
  end
end
