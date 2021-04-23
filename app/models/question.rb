class Question < ApplicationRecord
  belongs_to :user
  belongs_to :author, class_name: "User", optional: true

  validates :text, presence: true
  validates :text, length: {maximum: 255}
  validates :author_id, null: false

  scope :answered, -> { where.not(answer: nil) }
  scope :unanswered, -> { where(answer: nil) }
end
