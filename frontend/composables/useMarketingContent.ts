export const featurePages: Record<string, { eyebrow: string; title: string; subtitle: string; icon: string; sections: { title: string; desc: string; icon: string; bg: string; color: string }[] }> = {
  inspections: {
    eyebrow: 'Feature', title: 'Inspections that get done right', subtitle: 'Compliant, complete DVIR forms every time — built mobile-first with offline support and automatic issue creation.',
    icon: 'mdi-clipboard-check-outline',
    sections: [
      { title: 'Dynamic form builder', desc: 'Build custom inspection forms for pre-trip, post-trip, daily forklift checks and more.', icon: 'mdi-format-list-checks', bg: '#eff6ff', color: '#2563eb' },
      { title: 'Mobile-first & offline', desc: 'Full-screen, swipe-friendly interface for drivers. Syncs automatically when back online.', icon: 'mdi-cellphone-link', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Media capture', desc: 'Photo and video of defects with automatic GPS and timestamp watermarking.', icon: 'mdi-camera', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Pass / fail logic', desc: 'Failing a critical item automatically creates an issue and takes the vehicle out of service.', icon: 'mdi-alert-circle-check', bg: '#fef2f2', color: '#dc2626' },
    ],
  },
  'work-orders': {
    eyebrow: 'Feature', title: 'Work orders, planned and approved', subtitle: 'Plan, schedule and approve service tasks — in-house or outsourced — with full time, labor and parts tracking.',
    icon: 'mdi-clipboard-list-outline',
    sections: [
      { title: 'Full lifecycle', desc: 'Open → Assigned → Parts Ordered → In Progress → Resolved → Closed.', icon: 'mdi-transit-connection-variant', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Internal vs external', desc: 'Assign to in-house mechanics or external repair shops.', icon: 'mdi-swap-horizontal', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Time & labor tracking', desc: 'Mechanics clock in and out of specific work orders.', icon: 'mdi-clock-outline', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Parts linking', desc: 'Pull parts directly from inventory onto the work order.', icon: 'mdi-package-variant', bg: '#faf5ff', color: '#9333ea' },
      { title: 'Communication threads', desc: 'Internal notes for mechanics, external notes visible to drivers and managers.', icon: 'mdi-comment-text-multiple', bg: '#fffbeb', color: '#d97706' },
      { title: 'Cost guardrails', desc: 'Approval logic and thresholds keep every decision within budget.', icon: 'mdi-cash-lock', bg: '#fef2f2', color: '#dc2626' },
    ],
  },
  'parts-inventory': {
    eyebrow: 'Feature', title: 'Parts inventory without stockouts', subtitle: 'Control costs and avoid stockouts with multi-location tracking, barcode scanning and automated reordering.',
    icon: 'mdi-package-variant-closed',
    sections: [
      { title: 'Multi-location', desc: 'Track stock across warehouses, satellite yards and service trucks.', icon: 'mdi-map-marker-multiple', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'SKU management', desc: 'Categorization, min/max stock levels and bin locations.', icon: 'mdi-barcode', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Barcode scanning', desc: 'Use mobile device cameras to scan parts in and out.', icon: 'mdi-qrcode-scan', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Automated reordering', desc: 'When stock hits the minimum threshold, auto-create a purchase order.', icon: 'mdi-cart-arrow-down', bg: '#fff7ed', color: '#ea580c' },
      { title: 'FIFO / LIFO costing', desc: 'Accurate financial reporting with your chosen costing method.', icon: 'mdi-cash-100', bg: '#faf5ff', color: '#9333ea' },
    ],
  },
  'preventive-maintenance': {
    eyebrow: 'Feature', title: 'Preventive maintenance that runs itself', subtitle: 'Increase uptime and reduce breakdowns with multi-trigger reminders and automated work order generation.',
    icon: 'mdi-calendar-clock',
    sections: [
      { title: 'Multi-trigger logic', desc: 'Reminders based on time, mileage or engine hours.', icon: 'mdi-bell-ring', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Meter entry', desc: 'Easy interface for drivers and mechanics to update odometers and hour meters.', icon: 'mdi-counter', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Escalation matrix', desc: 'From email reminders to blocking dispatch when overdue.', icon: 'mdi-stairs-up', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Auto work orders', desc: 'Automatically convert a reminder into a draft work order.', icon: 'mdi-file-document-edit', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'OEM guidelines', desc: 'Automate maintenance programs based on manufacturer schedules.', icon: 'mdi-book-open-variant', bg: '#eff6ff', color: '#2563eb' },
    ],
  },
  'driver-assignments': {
    eyebrow: 'Feature', title: 'Driver assignments made simple', subtitle: 'Assign and manage schedules with ease. Track licenses, medical cards and MVR status in one place.',
    icon: 'mdi-account-group',
    sections: [
      { title: 'Driver profiles', desc: 'License class, expiration, medical card expiry and MVR status.', icon: 'mdi-card-account-details', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Assignment scheduling', desc: 'Assign vehicles to drivers with start and end dates.', icon: 'mdi-calendar-month', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Compliance tracking', desc: 'Never miss a license or medical renewal.', icon: 'mdi-shield-check', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Role-based access', desc: 'Drivers see only their assigned vehicles and inspections.', icon: 'mdi-lock', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
  reports: {
    eyebrow: 'Feature', title: 'Reports & analytics that matter', subtitle: 'Track every metric that matters with a report builder, scheduled exports and benchmarking.',
    icon: 'mdi-chart-line',
    sections: [
      { title: 'Report builder', desc: 'Drag-and-drop metrics, dimensions and filters.', icon: 'mdi-view-dashboard-edit', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Standard library', desc: 'Cost per mile, fuel efficiency, mechanic utilization, fleet aging.', icon: 'mdi-library-shelves', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Scheduled exports', desc: 'Automated PDF, Excel and CSV generation via background workers.', icon: 'mdi-clock-export', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Benchmarking', desc: 'Compare vehicle performance against fleet or industry averages.', icon: 'mdi-chart-bell-curve', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
  dashboards: {
    eyebrow: 'Feature', title: 'See your operation at a glance', subtitle: 'Customizable dashboards with live KPIs, interactive charts and a WebSocket-driven alert feed.',
    icon: 'mdi-view-dashboard-outline',
    sections: [
      { title: 'Drag-and-drop widgets', desc: 'Customize your layout with gridstack.', icon: 'mdi-widgets', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Global KPIs', desc: 'TCO, utilization, fuel efficiency and ROI per vehicle.', icon: 'mdi-chart-donut', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Live alert feed', desc: 'Real-time WebSocket updates for engine faults, accidents and geofence exits.', icon: 'mdi-bell-ring', bg: '#fef2f2', color: '#dc2626' },
      { title: 'Upcoming tasks', desc: 'Next 7 days of scheduled services and expiring documents.', icon: 'mdi-calendar-clock', bg: '#fff7ed', color: '#ea580c' },
    ],
  },
  'smart-uploads': {
    eyebrow: 'Feature', title: 'Smart uploads: invoices to data', subtitle: 'Instantly capture data from invoices and inspection forms with OCR — turn paperwork into actionable records.',
    icon: 'mdi-upload',
    sections: [
      { title: 'OCR extraction', desc: 'Auto-extract cost, gallons and price per gallon from receipts.', icon: 'mdi-text-recognition', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Invoice capture', desc: 'Turn invoices into service records and fuel transactions.', icon: 'mdi-file-document', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Inspection forms', desc: 'Digitize paper inspection forms in seconds.', icon: 'mdi-clipboard-text', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Validation', desc: 'Review and confirm extracted data before saving.', icon: 'mdi-check-decagram', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
}

export const solutionPages: Record<string, { eyebrow: string; title: string; subtitle: string; icon: string; sections: { title: string; desc: string; icon: string; bg: string; color: string }[] }> = {
  'fleet-management': {
    eyebrow: 'Solution', title: 'Fleet Management Software', subtitle: 'Know every detail about your vehicles — from specs and VIN decoding to depreciation and document tracking.',
    icon: 'mdi-car-multiple',
    sections: [
      { title: 'Asset hierarchy', desc: 'Vehicles, trailers, equipment and non-powered assets in one place.', icon: 'mdi-format-list-bulleted', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'VIN decoding', desc: 'Automatic make, model, year, engine and transmission via VIN API.', icon: 'mdi-database-search', bg: '#eff6ff', color: '#2563eb' },
      { title: 'Document vault', desc: 'Insurance, registration, titles with expiry tracking.', icon: 'mdi-file-document-multiple', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Depreciation tracker', desc: 'Straight-line or declining balance, automatically.', icon: 'mdi-chart-line-variant', bg: '#fff7ed', color: '#ea580c' },
      { title: 'EV management', desc: 'Battery SoH, SoC, charging schedules and energy per mile.', icon: 'mdi-flash', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
  'fleet-maintenance': {
    eyebrow: 'Solution', title: 'Fleet Maintenance Software', subtitle: 'Stay on top of routines and repairs with preventive maintenance, work orders and a full service history timeline.',
    icon: 'mdi-wrench',
    sections: [
      { title: 'Preventive maintenance', desc: 'Time, mileage and engine-hour triggers with auto work orders.', icon: 'mdi-calendar-clock', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Work order lifecycle', desc: 'Full status tracking from open to closed with parts and labor.', icon: 'mdi-clipboard-list', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Service timeline', desc: 'Visual history of everything that has happened to a vehicle.', icon: 'mdi-timeline-text', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Downtime tracking', desc: 'Calculate exactly how long a vehicle was out of service.', icon: 'mdi-timer-sand', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Vendor ratings', desc: 'Rate external shops on cost, quality and turnaround.', icon: 'mdi-star-check', bg: '#faf5ff', color: '#9333ea' },
    ],
  },
  'fuel-management': {
    eyebrow: 'Solution', title: 'Fuel Management Software', subtitle: 'Collect fuel data and control costs with card integration, fraud detection and idling analytics.',
    icon: 'mdi-gas-station',
    sections: [
      { title: 'Fuel card integration', desc: 'Direct API sync with WEX, Comdata, Fleetcor and BP.', icon: 'mdi-credit-card-chip', bg: '#fff7ed', color: '#ea580c' },
      { title: 'OCR receipt capture', desc: 'Upload receipts and auto-extract cost, gallons and price per gallon.', icon: 'mdi-text-recognition', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Fraud detection', desc: 'AI alerts for wrong fuel type, double fills and weekend fueling.', icon: 'mdi-shield-alert', bg: '#fef2f2', color: '#dc2626' },
      { title: 'Idling analytics', desc: 'Cost of excessive idling based on fuel burn rates.', icon: 'mdi-clock-alert', bg: '#ecfeff', color: '#0891b2' },
      { title: 'EV charging', desc: 'Sync with ChargePoint and Tesla for charging session data.', icon: 'mdi-flash', bg: '#f0fdf4', color: '#16a34a' },
    ],
  },
  'tool-management': {
    eyebrow: 'Solution', title: 'Tool & Equipment Management', subtitle: 'Track equipment alongside your vehicles with QR check-in/check-out and calibration tracking.',
    icon: 'mdi-toolbox',
    sections: [
      { title: 'Categorization', desc: 'Heavy machinery, power tools and safety gear.', icon: 'mdi-format-list-bulleted-type', bg: '#faf5ff', color: '#9333ea' },
      { title: 'Check-in / check-out', desc: 'QR and barcode scanning to assign tools to staff and vehicles.', icon: 'mdi-qrcode-scan', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Calibration tracking', desc: 'Alerts for tools requiring annual calibration.', icon: 'mdi-tune', bg: '#fff7ed', color: '#ea580c' },
    ],
  },
  'multi-location': {
    eyebrow: 'Solution', title: 'Multi-Location Fleet Management', subtitle: 'Manage your fleet across multiple locations with location-scoped access and consolidated reporting.',
    icon: 'mdi-map-marker-multiple',
    sections: [
      { title: 'Location scoping', desc: 'Managers see only vehicles at their specific yard.', icon: 'mdi-map-marker-radius', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Consolidated reporting', desc: 'Roll up data across all locations or drill into one.', icon: 'mdi-chart-multiple', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Cross-location inventory', desc: 'Track parts and tools across every site.', icon: 'mdi-package-variant', bg: '#f0fdf4', color: '#16a34a' },
    ],
  },
  intelligence: {
    eyebrow: 'Solution', title: 'Fleet Intelligence', subtitle: 'Spend less time on repetitive tasks with AI Service Advisor, automations and smart assessments.',
    icon: 'mdi-brain',
    sections: [
      { title: 'AI Service Advisor', desc: 'Evaluates repair orders, flags exceptions and keeps approvals in guardrails.', icon: 'mdi-robot', bg: '#faf5ff', color: '#9333ea' },
      { title: 'Smart assessments', desc: 'Identify the outliers with AI-powered service assessments.', icon: 'mdi-chart-bell-curve', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Workflow automations', desc: 'Automate repetitive maintenance and approval workflows.', icon: 'mdi-transit-connection-variant', bg: '#fef2f2', color: '#dc2626' },
      { title: 'Decision patterns', desc: 'Captures decision patterns over time to improve recommendations.', icon: 'mdi-database-clock', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
}

export const industryPages: Record<string, { eyebrow: string; title: string; subtitle: string; icon: string; sections: { title: string; desc: string; icon: string; bg: string; color: string }[] }> = {
  construction: {
    eyebrow: 'Industry', title: 'Construction', subtitle: 'Stay on time and on budget for every job with equipment tracking and maintenance that keeps machinery moving.',
    icon: 'mdi-hard-hat',
    sections: [
      { title: 'Equipment tracking', desc: 'Heavy machinery alongside your vehicles in one platform.', icon: 'mdi-bulldozer', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Engine-hour PM', desc: 'Preventive maintenance triggered by engine hours, not just mileage.', icon: 'mdi-counter', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Tool check-out', desc: 'Track power tools and safety gear assigned to crews.', icon: 'mdi-toolbox', bg: '#faf5ff', color: '#9333ea' },
      { title: 'Job costing', desc: 'Tie fuel and maintenance costs back to projects.', icon: 'mdi-cash', bg: '#f0fdf4', color: '#16a34a' },
    ],
  },
  'service-providers': {
    eyebrow: 'Industry', title: 'Service Providers', subtitle: 'Maximize fleet uptime and guarantee reliability so your technicians always arrive on time.',
    icon: 'mdi-account-tie',
    sections: [
      { title: 'Uptime focus', desc: 'Preventive maintenance that keeps service vehicles on the road.', icon: 'mdi-truck-check', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Driver assignments', desc: 'Match the right vehicle to the right technician.', icon: 'mdi-account-group', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Route dispatch', desc: 'Assign vehicles to jobs and track route adherence.', icon: 'mdi-map-marker-path', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
  transportation: {
    eyebrow: 'Industry', title: 'Transportation & Logistics', subtitle: 'Integrate with ELD and improve efficiency across your trucking fleet.',
    icon: 'mdi-truck-fast',
    sections: [
      { title: 'ELD integration', desc: 'Sync telematics and ELD data to auto-start maintenance.', icon: 'mdi-satellite-variant', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Mileage tracking', desc: 'Automated odometer updates from telematics.', icon: 'mdi-counter', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Fuel cost control', desc: 'Fraud detection and idling analytics across the fleet.', icon: 'mdi-gas-station', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Compliance', desc: 'Inspections and document expiry tracking for DOT.', icon: 'mdi-shield-check', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
  government: {
    eyebrow: 'Industry', title: 'Government', subtitle: 'Improve compliance and reduce operating expenses with full audit trails and transparent reporting.',
    icon: 'mdi-domain',
    sections: [
      { title: 'Audit logs', desc: 'Track every action — who viewed, changed or deleted a record.', icon: 'mdi-clipboard-text-clock', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Granular RBAC', desc: 'Role-based access down to the location and module.', icon: 'mdi-lock', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Transparent reporting', desc: 'Standard reports and scheduled exports for stakeholders.', icon: 'mdi-chart-line', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'SSO', desc: 'Single sign-on for secure, centralized access.', icon: 'mdi-key', bg: '#faf5ff', color: '#9333ea' },
    ],
  },
}
