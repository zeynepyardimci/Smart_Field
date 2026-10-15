require_relative "../test_helper"

class WorkOrderTest < ActiveSupport::TestCase
  def setup
    @manager = User.create!(
      name: "Manager Alice",
      email: "alice@test.com",
      password: "password123",
      role: :manager
    )
    @technician = User.create!(
      name: "Tech Bob",
      email: "bob@test.com",
      password: "password123",
      role: :technician
    )
    @work_order = WorkOrder.create!(
      title: "MRI Preventative Maintenance",
      customer_name: "Mayo Clinic",
      facility_location: "Rochester, MN",
      asset_name: "GE MRI",
      priority: :critical,
      status: :assigned,
      due_at: 2.hours.from_now,
      created_by: @manager,
      assigned_to: @technician
    )
  end

  test "generates unique order number on create" do
    assert @work_order.order_number.present?
    assert @work_order.order_number.start_with?("WO-")
  end

  test "detects sla breached correctly" do
    assert_not @work_order.sla_breached?

    @work_order.update!(due_at: 1.hour.ago)
    assert @work_order.sla_breached?

    @work_order.update!(status: :completed)
    assert_not @work_order.sla_breached?
  end

  test "state machine allows valid transitions and records audit trail" do
    assert @work_order.can_transition_to?(:in_progress)

    success = @work_order.transition_to!(:in_progress, by_user: @technician, note: "Arrived at site")
    assert success
    assert_equal "in_progress", @work_order.reload.status
    assert @work_order.started_at.present?

    transition = @work_order.status_transitions.first
    assert_equal "assigned", transition.from_status
    assert_equal "in_progress", transition.to_status
    assert_equal @technician, transition.changed_by
    assert_equal "Arrived at site", transition.note
  end

  test "state machine prevents invalid transitions" do
    # From assigned, cannot jump directly to completed without in_progress
    assert_not @work_order.can_transition_to?(:completed)

    result = @work_order.transition_to!(:completed, by_user: @technician)
    assert_not result
    assert_equal "assigned", @work_order.reload.status
  end
end
