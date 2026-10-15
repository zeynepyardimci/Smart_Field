# Clear existing data
StatusTransition.delete_all
WorkOrder.delete_all
User.delete_all

# 1. Users
manager = User.create!(
  name: "Sarah Jenkins",
  email: "sarah.jenkins@smartfield.io",
  password: "password123",
  role: :manager,
  title: "Head of Field Operations (GE Healthcare Account)",
  phone: "+1-555-0199"
)

technician_1 = User.create!(
  name: "Marcus Vance",
  email: "marcus.vance@smartfield.io",
  password: "password123",
  role: :technician,
  title: "Lead Bio-Medical Field Engineer",
  phone: "+1-555-0182"
)

technician_2 = User.create!(
  name: "Elena Rostova",
  email: "elena.rostova@smartfield.io",
  password: "password123",
  role: :technician,
  title: "Senior Imaging Systems Specialist",
  phone: "+1-555-0144"
)

# 2. Realistic Work Orders (Enterprise Fortune 500 Field Service)
wo1 = WorkOrder.create!(
  title: "SIGNA Pioneer 3.0T MRI Scanner - RF Coil Calibration & Cryogen Level Check",
  description: "Quarterly preventative maintenance and liquid helium level inspection for GE Healthcare imaging system. Customer reported minor artifacting on channel 4.",
  customer_name: "Johns Hopkins Medical Center",
  facility_location: "Baltimore, MD - Radiology Wing B2",
  asset_name: "GE SIGNA Pioneer 3.0T MRI",
  asset_serial_number: "GE-MRI-99482-P",
  priority: :critical,
  status: :assigned,
  due_at: 4.hours.from_now,
  created_by: manager,
  assigned_to: technician_1
)
StatusTransition.create!(
  work_order: wo1,
  changed_by: manager,
  from_status: :new_order,
  to_status: :assigned,
  note: "Urgent hospital imaging line ticket. Assigned to Marcus Vance."
)

wo2 = WorkOrder.create!(
  title: "Revolution Apex CT Scanner - Detector Array Firmware Update",
  description: "Critical safety update patch deployment for high-resolution cardiac imaging detector array. Machine must be recalibrated before clinical morning intake.",
  customer_name: "Mayo Clinic - St. Marys Hospital",
  facility_location: "Rochester, MN - Emergency Radiology",
  asset_name: "GE Revolution Apex CT",
  asset_serial_number: "GE-CT-77310-A",
  priority: :high,
  status: :in_progress,
  due_at: 2.hours.ago, # Intentionally SLA breached for real-time badge testing!
  started_at: 1.hour.ago,
  created_by: manager,
  assigned_to: technician_1
)
StatusTransition.create!(
  work_order: wo2,
  changed_by: manager,
  from_status: :new_order,
  to_status: :assigned,
  note: "Dispatched from regional control center."
)
StatusTransition.create!(
  work_order: wo2,
  changed_by: technician_1,
  from_status: :assigned,
  to_status: :in_progress,
  note: "On site at Radiology Unit 3. Initiating diagnostic test cycle."
)

wo3 = WorkOrder.create!(
  title: "Optima XR240amx Mobile X-Ray - Battery Pack Replacement",
  description: "Mobile X-Ray unit failing to hold charge for full ward rounds. Replace primary lithium-ion power bank and inspect drive motor linkages.",
  customer_name: "Cleveland Clinic Main Campus",
  facility_location: "Cleveland, OH - Intensive Care Unit",
  asset_name: "GE Optima XR240amx Mobile Digital X-Ray",
  asset_serial_number: "GE-XR-33120-M",
  priority: :medium,
  status: :new_order,
  due_at: 24.hours.from_now,
  created_by: manager
)

wo4 = WorkOrder.create!(
  title: "Infinia Hawkeye 4 SPECT/CT - Scintillation Camera Crystal Inspection",
  description: "Annual detector uniformity validation and PMT tube voltage realignment.",
  customer_name: "Cedars-Sinai Medical Center",
  facility_location: "Los Angeles, CA - Nuclear Medicine Dept",
  asset_name: "GE Infinia Hawkeye Nuclear Camera",
  asset_serial_number: "GE-NM-10492-H",
  priority: :low,
  status: :completed,
  due_at: 1.day.ago,
  started_at: 2.days.ago,
  completed_at: 1.day.ago,
  created_by: manager,
  assigned_to: technician_2
)
StatusTransition.create!(
  work_order: wo4,
  changed_by: manager,
  from_status: :new_order,
  to_status: :assigned,
  note: "Scheduled annual maintenance."
)
StatusTransition.create!(
  work_order: wo4,
  changed_by: technician_2,
  from_status: :assigned,
  to_status: :in_progress,
  note: "Beginning detector uniformity check."
)
StatusTransition.create!(
  work_order: wo4,
  changed_by: technician_2,
  from_status: :in_progress,
  to_status: :completed,
  note: "All calibrations within OEM specification. Return to clinical service."
)

puts "Seeding complete! Created #{User.count} users and #{WorkOrder.count} work orders."
