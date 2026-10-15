class User < ApplicationRecord
  has_secure_password

  enum :role, { manager: 0, technician: 1 }
  scope :technicians, -> { where(role: :technician) }
  scope :managers, -> { where(role: :manager) }

  has_many :created_work_orders, class_name: "WorkOrder", foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :assigned_work_orders, class_name: "WorkOrder", foreign_key: :assigned_to_id, dependent: :nullify
  has_many :status_transitions, foreign_key: :changed_by_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true
end
