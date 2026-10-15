module ApplicationHelper
  STATUS_LABELS = {
    "new_order"   => "Yeni",
    "assigned"    => "Atandı",
    "in_progress" => "İşlemde",
    "completed"   => "Tamamlandı",
    "blocked"     => "Bloke",
    "cancelled"   => "İptal"
  }.freeze

  PRIORITY_LABELS = {
    "critical" => "Kritik",
    "high"     => "Yüksek",
    "medium"   => "Orta",
    "low"      => "Düşük"
  }.freeze

  ROLE_LABELS = {
    "manager"    => "Yönetici",
    "technician" => "Saha Teknisyeni"
  }.freeze

  def work_order_status_label(status)
    STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  def work_order_priority_label(priority)
    PRIORITY_LABELS[priority.to_s] || priority.to_s.humanize
  end

  def user_role_label(role)
    ROLE_LABELS[role.to_s] || role.to_s.humanize
  end

  def humanize_duration(seconds)
    secs = seconds.to_i.abs
    if secs < 60
      "1 dk'dan az"
    elsif secs < 3600
      "#{secs / 60} dk"
    elsif secs < 86400
      hours = secs / 3600
      mins = (secs % 3600) / 60
      mins > 0 ? "#{hours} sa #{mins} dk" : "#{hours} saat"
    else
      days = secs / 86400
      hours = (secs % 86400) / 3600
      hours > 0 ? "#{days} gün #{hours} sa" : "#{days} gün"
    end
  end

  def sla_badge_content(work_order)
    if work_order.completed?
      { class: "completed", text: "✓ Tamamlandı" }
    elsif work_order.sla_breached?
      duration = humanize_duration(Time.current - work_order.due_at)
      { class: "breached", text: "🚨 SLA Aşıldı (#{duration} önce)" }
    else
      duration = humanize_duration(work_order.due_at - Time.current)
      { class: "ontimer", text: "⏱️ #{duration} kaldı" }
    end
  end
end
