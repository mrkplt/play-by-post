class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      # The URL of the page the submitter was on when they opened the feedback
      # modal — captured client-side so the report records what it was about.
      t.string :url

      t.timestamps
    end
  end
end
