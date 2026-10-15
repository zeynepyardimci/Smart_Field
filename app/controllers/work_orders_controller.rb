class WorkOrdersController < ApplicationController
  before_action :require_user
  before_action :set_work_order, only: [ :show, :edit, :update, :transition, :destroy ]
  before_action :require_manager, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    # Scope by role: Technicians see assigned to them or unassigned; Managers see all
    @scope = params[:filter] || "all"
    
    base_orders = if current_user.manager?
                    WorkOrder.all
                  else
                    WorkOrder.where(assigned_to: [ current_user, nil ])
                  end

    @work_orders = case @scope
                   when "my_tasks"
                     base_orders.where(assigned_to: current_user)
                   when "sla_breached"
                     base_orders.sla_breached
                   when "critical"
                     base_orders.where(priority: :critical)
                   when "in_progress"
                     base_orders.where(status: :in_progress)
                   when "completed"
                     base_orders.where(status: :completed)
                   else
                     base_orders.active
                   end.order(priority: :desc, due_at: :asc)

    @sla_breach_count = base_orders.sla_breached.count
    @critical_count = base_orders.active.where(priority: :critical).count
    @in_progress_count = base_orders.where(status: :in_progress).count
    @total_active_count = base_orders.active.count
  end

  def show
    @transitions = @work_order.status_transitions.includes(:changed_by)
  end

  def new
    @work_order = WorkOrder.new(due_at: 8.hours.from_now)
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.created_by = current_user
    @work_order.status = @work_order.assigned_to.present? ? :assigned : :new_order

    if @work_order.save
      StatusTransition.create!(
        work_order: @work_order,
        changed_by: current_user,
        from_status: :new_order,
        to_status: @work_order.status,
        note: "İş emri oluşturuldu."
      )
      redirect_to work_orders_path, notice: "İş emri ##{@work_order.order_number} başarıyla oluşturuldu."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @work_order.update(work_order_params)
      redirect_to @work_order, notice: "İş emri güncellendi."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Hotwire One-Click Status Transition Action
  def transition
    target_status = params[:target_status]
    note = params[:note].presence || "Durum güncellendi: #{target_status.humanize}"

    if @work_order.transition_to!(target_status, by_user: current_user, note: note)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("work_order_#{@work_order.id}", partial: "work_orders/work_order_card", locals: { work_order: @work_order }),
            turbo_stream.update("flash_messages", partial: "shared/flash", locals: { notice: "##{@work_order.order_number} durumu '#{target_status.humanize}' olarak güncellendi." })
          ]
        end
        format.html { redirect_to work_orders_path, notice: "Durum güncellendi: #{target_status.humanize}" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash", locals: { alert: @work_order.errors.full_messages.join(", ") })
        end
        format.html { redirect_to work_orders_path, alert: "Geçiş yapılamadı: #{@work_order.errors.full_messages.join(', ')}" }
      end
    end
  end

  def destroy
    @work_order.destroy
    redirect_to work_orders_path, notice: "İş emri silindi."
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def work_order_params
    params.require(:work_order).permit(
      :title, :description, :priority, :due_at,
      :customer_name, :facility_location, :asset_name, :asset_serial_number,
      :assigned_to_id
    )
  end
end
