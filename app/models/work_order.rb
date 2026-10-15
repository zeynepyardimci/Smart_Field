class WorkOrder < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :assigned_to, class_name: "User", optional: true
  has_many :status_transitions, -> { order(created_at: :desc) }, dependent: :destroy

  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }
  enum :status, {
    new_order: 0,
    assigned: 1,
    in_progress: 2,
    completed: 3,
    blocked: 4,
    cancelled: 5
  }

  validates :order_number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :customer_name, presence: true
  validates :facility_location, presence: true
  validates :asset_name, presence: true
  validates :due_at, presence: true
  validates :priority, presence: true
  validates :status, presence: true

  before_validation :generate_order_number, on: :create

  scope :active, -> { where.not(status: [ :completed, :cancelled ]) }
  scope :sla_breached, -> { active.where("due_at < ?", Time.current) }
  scope :critical_priority, -> { where(priority: :critical) }

  # Status State Machine allowed transitions
  ALLOWED_TRANSITIONS = {
    "new_order"   => [ "assigned", "cancelled" ],
    "assigned"    => [ "in_progress", "blocked", "cancelled" ],
    "in_progress" => [ "completed", "blocked", "cancelled" ],
    "blocked"     => [ "in_progress", "cancelled" ],
    "completed"   => [],
    "cancelled"   => []
  }.freeze

  def can_transition_to?(target_status)
    ALLOWED_TRANSITIONS[status.to_s]&.include?(target_status.to_s)
  end

  def transition_to!(target_status, by_user:, note: nil)
    target_status_str = target_status.to_s
    unless can_transition_to?(target_status_str)
      errors.add(:status, "cannot transition from #{status} to #{target_status_str}")
      return false
    end

    transaction do
      old_status = self.status
      self.status = target_status_str
      self.started_at = Time.current if target_status_str == "in_progress" && started_at.blank?
      self.completed_at = Time.current if target_status_str == "completed"

      save!

      status_transitions.create!(
        changed_by: by_user,
        from_status: old_status,
        to_status: target_status_str,
        note: note
      )
    end
    true
  end

  def sla_breached?
    due_at.present? && due_at < Time.current && !completed? && !cancelled?
  end

  def sla_time_remaining
    return 0 if sla_breached? || due_at.blank?
    (due_at - Time.current).to_i
  end

  def priority_badge_class
    case priority
    when "critical" then "badge-critical"
    when "high"     then "badge-high"
    when "medium"   then "badge-medium"
    else "badge-low"
    end
  end

  def status_badge_class
    case status
    when "new_order"   then "badge-new"
    when "assigned"    then "badge-assigned"
    when "in_progress" then "badge-in-progress"
    when "completed"   then "badge-completed"
    when "blocked"     then "badge-blocked"
    else "badge-cancelled"
    end
  end

  private

  def generate_order_number
    return if order_number.present?
    self.order_number = "WO-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end
