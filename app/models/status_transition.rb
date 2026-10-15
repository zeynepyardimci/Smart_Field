class StatusTransition < ApplicationRecord
  belongs_to :work_order
  belongs_to :changed_by, class_name: "User"

  enum :from_status, {
    new_order: 0,
    assigned: 1,
    in_progress: 2,
    completed: 3,
    blocked: 4,
    cancelled: 5
  }, prefix: :from

  enum :to_status, {
    new_order: 0,
    assigned: 1,
    in_progress: 2,
    completed: 3,
    blocked: 4,
    cancelled: 5
  }, prefix: :to

  validates :from_status, :to_status, presence: true
end
