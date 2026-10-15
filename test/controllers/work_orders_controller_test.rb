require_relative "../test_helper"

class WorkOrdersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @manager = User.create!(
      name: "Manager Alice",
      email: "alice_mgmt@test.com",
      password: "password123",
      role: :manager
    )
    @tech1 = User.create!(
      name: "Tech Bob",
      email: "bob_tech@test.com",
      password: "password123",
      role: :technician
    )
    @tech2 = User.create!(
      name: "Tech Charlie",
      email: "charlie_tech@test.com",
      password: "password123",
      role: :technician
    )
    @work_order = WorkOrder.create!(
      title: "MRI Preventative Maintenance",
      customer_name: "Mayo Clinic",
      facility_location: "Rochester, MN",
      asset_name: "GE SIGNA Pioneer 3.0T MRI",
      priority: :critical,
      status: :assigned,
      due_at: 2.hours.from_now,
      created_by: @manager,
      assigned_to: @tech1
    )
  end

  # Senaryo 1: İş emri oluşturulur (Work Order is created by Manager)
  test "1. manager can create a valid work order" do
    log_in_as(@manager)
    assert_difference("WorkOrder.count", 1) do
      post work_orders_path, params: {
        work_order: {
          title: "CT Detector Alignment",
          customer_name: "Johns Hopkins",
          facility_location: "Baltimore, MD",
          asset_name: "GE Revolution Apex CT",
          priority: "high",
          due_at: 6.hours.from_now
        }
      }
    end
    assert_redirected_to work_orders_path
    follow_redirect!
    assert_select ".alert-notice, .flash-notice", text: /başarıyla oluşturuldu/
  end

  # Senaryo 2: İş emri personele atanır (Work Order is assigned to Technician)
  test "2. work order can be created and assigned to a technician" do
    log_in_as(@manager)
    post work_orders_path, params: {
      work_order: {
        title: "X-Ray Calibration",
        customer_name: "Cleveland Clinic",
        facility_location: "Cleveland, OH",
        asset_name: "GE Optima XR240amx",
        priority: "medium",
        due_at: 12.hours.from_now,
        assigned_to_id: @tech1.id
      }
    }
    new_order = WorkOrder.last
    assert_equal @tech1, new_order.assigned_to
    assert_equal "assigned", new_order.status
  end

  # Senaryo 3: Geçerli durum geçişi yapılır (Valid inline status transition)
  test "3. allows valid status transition and updates record" do
    log_in_as(@tech1)
    patch transition_work_order_path(@work_order), params: {
      target_status: "in_progress",
      note: "Started work on site"
    }
    assert_redirected_to work_orders_path
    @work_order.reload
    assert_equal "in_progress", @work_order.status
    assert @work_order.started_at.present?
    assert_equal 1, @work_order.status_transitions.count
    assert_equal "Started work on site", @work_order.status_transitions.first.note
  end

  # Senaryo 4: Geçersiz durum geçişi reddedilir (Invalid status transition is rejected)
  test "4. rejects invalid status transition with error" do
    log_in_as(@tech1)
    # Cannot jump directly from assigned to completed without in_progress
    patch transition_work_order_path(@work_order), params: {
      target_status: "completed"
    }
    @work_order.reload
    assert_equal "assigned", @work_order.status
    assert_nil @work_order.completed_at
  end

  # Senaryo 5: Son tarihi geçen tamamlanmamış iş gecikmiş görünür (SLA Breach)
  test "5. overdue uncompleted work order is marked as SLA breached" do
    log_in_as(@manager)
    @work_order.update!(due_at: 1.hour.ago)
    assert @work_order.sla_breached?

    get work_orders_path, params: { filter: "sla_breached" }
    assert_response :success
    assert_select ".wo-number", text: @work_order.order_number
    assert_select ".sla-badge.breached"
  end

  # Senaryo 6: Tamamlanmış iş gecikmiş olarak gösterilmez (Completed work order is never breached)
  test "6. completed work order is not marked as SLA breached even if past due_at" do
    log_in_as(@manager)
    @work_order.update!(due_at: 1.day.ago, status: :completed, completed_at: 1.day.ago)
    assert_not @work_order.sla_breached?

    get work_orders_path, params: { filter: "sla_breached" }
    assert_response :success
    # Completed orders must NOT appear in the SLA breached list
    assert_select ".wo-number", text: @work_order.order_number, count: 0
  end

  # Senaryo 7: Geçersiz giriş kullanıcıya anlaşılır hata verir (Validation errors on invalid input)
  test "7. invalid work order submission returns 422 unprocessable_entity with errors" do
    log_in_as(@manager)
    assert_no_difference("WorkOrder.count") do
      post work_orders_path, params: {
        work_order: {
          title: "", # Empty title should fail
          customer_name: "",
          due_at: nil
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors", minimum: 1
  end

  # Senaryo 8: Yetkisiz kullanıcı izinsiz işlem yapamaz (Authentication and Authorization)
  test "8. unauthenticated visitor is redirected to login" do
    get work_orders_path
    assert_redirected_to login_path
  end

  test "8b. technician cannot access new work order form or create orders" do
    log_in_as(@tech1)
    get new_work_order_path
    assert_redirected_to root_path

    assert_no_difference("WorkOrder.count") do
      post work_orders_path, params: {
        work_order: {
          title: "Unauthorized Order",
          customer_name: "Hospital",
          facility_location: "NYC",
          asset_name: "Machine",
          due_at: 1.hour.from_now
        }
      }
    end
    assert_redirected_to root_path
  end
end
