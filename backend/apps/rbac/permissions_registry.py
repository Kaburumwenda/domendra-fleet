"""
Static registry of all permissions available in the system.

This is the single source of truth for what permissions exist. It is used
by the ``seed_rbac`` data migration and the ``sync_permissions`` management
command to populate the ``Permission`` table per tenant.

Structure
---------
Each entry is a tuple ``(module, label, icon, actions)`` where
``actions`` is a list of (action, label, description) tuples.

To add a new permission for a module, simply add the action tuple here and
run ``python manage.py sync_permissions`` (or the next migration).
"""

# (module_key, module_label, icon, [
#     (action, permission_label, description),
#     ...
# ])
PERMISSIONS_REGISTRY = [
    (
        'vehicles', 'Vehicles', 'mdi-car',
        [
            ('view', 'View Vehicles', 'View vehicle list and details'),
            ('create', 'Add Vehicles', 'Create new vehicle records'),
            ('update', 'Edit Vehicles', 'Modify vehicle information'),
            ('delete', 'Delete Vehicles', 'Remove vehicles from the fleet'),
            ('export', 'Export Vehicles', 'Export vehicle data to CSV/Excel'),
        ],
    ),
    (
        'drivers', 'Drivers', 'mdi-steering',
        [
            ('view', 'View Drivers', 'View driver list and profiles'),
            ('create', 'Add Drivers', 'Create new driver records'),
            ('update', 'Edit Drivers', 'Modify driver information'),
            ('delete', 'Delete Drivers', 'Remove driver records'),
            ('export', 'Export Drivers', 'Export driver data'),
        ],
    ),
    (
        'dispatch', 'Dispatch', 'mdi-map-outline',
        [
            ('view', 'View Dispatch', 'View dispatch board and jobs'),
            ('create', 'Create Jobs', 'Create new dispatch jobs'),
            ('update', 'Edit Jobs', 'Modify dispatch jobs and stops'),
            ('delete', 'Delete Jobs', 'Remove dispatch jobs'),
            ('assign', 'Assign Resources', 'Assign drivers and vehicles to jobs'),
        ],
    ),
    (
        'transfers', 'Transfers', 'mdi-car-multiple',
        [
            ('view', 'View Transfers', 'View transfer bookings and live tracking'),
            ('create', 'Create Transfers', 'Create new transfer bookings'),
            ('update', 'Edit Transfers', 'Modify transfer bookings and assignments'),
            ('delete', 'Delete Transfers', 'Cancel or remove transfer bookings'),
            ('assign', 'Assign Resources', 'Assign vehicles and drivers to transfers'),
            ('export', 'Export Transfers', 'Export transfer booking data'),
        ],
    ),
    (
        'maintenance', 'Maintenance', 'mdi-wrench-outline',
        [
            ('view', 'View Maintenance', 'View work orders, issues, and services'),
            ('create', 'Create Work Orders', 'Create work orders and issues'),
            ('update', 'Edit Work Orders', 'Modify work orders and issues'),
            ('delete', 'Delete Records', 'Remove work orders and issues'),
            ('approve', 'Approve Work Orders', 'Approve work order completion'),
        ],
    ),
    (
        'inspections', 'Inspections', 'mdi-clipboard-check-outline',
        [
            ('view', 'View Inspections', 'View inspection reports'),
            ('create', 'Create Inspections', 'Submit new inspection reports'),
            ('update', 'Edit Inspections', 'Modify inspection reports'),
            ('delete', 'Delete Inspections', 'Remove inspection records'),
        ],
    ),
    (
        'inventory', 'Parts & Inventory', 'mdi-package-variant-closed',
        [
            ('view', 'View Inventory', 'View parts and inventory items'),
            ('create', 'Add Items', 'Create new inventory items'),
            ('update', 'Edit Items', 'Modify items and stock levels'),
            ('delete', 'Delete Items', 'Remove inventory items'),
            ('export', 'Export Inventory', 'Export inventory data'),
        ],
    ),
    (
        'fuel', 'Fuel & Energy', 'mdi-gas-station',
        [
            ('view', 'View Fuel Data', 'View fuel transactions and analytics'),
            ('create', 'Log Fuel', 'Record new fuel transactions'),
            ('update', 'Edit Fuel Records', 'Modify fuel transactions'),
            ('delete', 'Delete Fuel Records', 'Remove fuel transactions'),
            ('export', 'Export Fuel Data', 'Export fuel transaction data'),
        ],
    ),
    (
        'ifta', 'IFTA & Fuel Tax', 'mdi-map-marker-path',
        [
            ('view', 'View IFTA', 'View IFTA trip logs and reports'),
            ('create', 'Add Trip Logs', 'Create IFTA trip log entries'),
            ('update', 'Edit Trip Logs', 'Modify IFTA trip log entries'),
            ('delete', 'Delete Trip Logs', 'Remove IFTA trip log entries'),
            ('export', 'Export IFTA Reports', 'Export quarterly IFTA reports'),
        ],
    ),
    (
        'telematics', 'Telematics & GPS', 'mdi-crosshairs-gps',
        [
            ('view', 'View Telematics', 'View live fleet map and GPS data'),
            ('create', 'Register Devices', 'Register new telematics devices'),
            ('update', 'Edit Telematics', 'Modify geofences and device settings'),
            ('delete', 'Delete Telematics', 'Remove devices and geofences'),
        ],
    ),
    (
        'rentals', 'Car Hire & Rental', 'mdi-car-key',
        [
            ('view', 'View Rentals', 'View rental agreements and customers'),
            ('create', 'Create Agreements', 'Create new rental agreements'),
            ('update', 'Edit Agreements', 'Modify rental agreements'),
            ('delete', 'Delete Agreements', 'Cancel or remove rental agreements'),
            ('export', 'Export Rental Data', 'Export rental data'),
        ],
    ),
    (
        'contacts', 'Contacts', 'mdi-card-account-details-outline',
        [
            ('view', 'View Contacts', 'View vendor and contact directory'),
            ('create', 'Add Contacts', 'Create new contacts'),
            ('update', 'Edit Contacts', 'Modify contact information'),
            ('delete', 'Delete Contacts', 'Remove contacts'),
        ],
    ),
    (
        'documents', 'Documents', 'mdi-file-document-outline',
        [
            ('view', 'View Documents', 'View document vault'),
            ('create', 'Upload Documents', 'Upload new documents'),
            ('update', 'Edit Documents', 'Modify document metadata'),
            ('delete', 'Delete Documents', 'Remove documents'),
        ],
    ),
    (
        'lessors', 'Lessors', 'mdi-handshake-outline',
        [
            ('view', 'View Lessors', 'View lessor contracts'),
            ('create', 'Add Lessors', 'Create lessor contracts'),
            ('update', 'Edit Lessors', 'Modify lessor contracts'),
            ('delete', 'Delete Lessors', 'Remove lessors'),
        ],
    ),
    (
        'equipment', 'Equipment', 'mdi-tools',
        [
            ('view', 'View Equipment', 'View equipment registry'),
            ('create', 'Add Equipment', 'Create new equipment records'),
            ('update', 'Edit Equipment', 'Modify equipment records'),
            ('delete', 'Delete Equipment', 'Remove equipment'),
        ],
    ),
    (
        'tires', 'Tires', 'mdi-tire',
        [
            ('view', 'View Tires', 'View tire inventory'),
            ('create', 'Add Tires', 'Register new tires'),
            ('update', 'Manage Tires', 'Mount, rotate, and edit tires'),
            ('delete', 'Delete Tires', 'Retire or remove tires'),
        ],
    ),
    (
        'accidents', 'Accidents', 'mdi-alert-circle-outline',
        [
            ('view', 'View Accidents', 'View accident records'),
            ('create', 'Report Accidents', 'Create new accident reports'),
            ('update', 'Edit Accidents', 'Modify accident records'),
            ('delete', 'Delete Accidents', 'Remove accident records'),
        ],
    ),
    (
        'recalls', 'Recalls', 'mdi-car-info',
        [
            ('view', 'View Recalls', 'View recall notices'),
            ('create', 'Create Recalls', 'Log new recall notices'),
            ('update', 'Edit Recalls', 'Modify recall records'),
            ('delete', 'Delete Recalls', 'Remove recall records'),
        ],
    ),
    (
        'garage', 'Garage', 'mdi-sitemap',
        [
            ('view', 'View Garage', 'View garage bays and schedule'),
            ('create', 'Manage Bays', 'Create garage bays and reservations'),
            ('update', 'Edit Schedule', 'Modify garage schedule'),
            ('delete', 'Delete Reservations', 'Cancel garage reservations'),
        ],
    ),
    (
        'reminders', 'Reminders', 'mdi-bell-outline',
        [
            ('view', 'View Reminders', 'View maintenance reminders'),
            ('create', 'Create Reminders', 'Set up new reminders'),
            ('update', 'Edit Reminders', 'Modify reminders'),
            ('delete', 'Delete Reminders', 'Remove reminders'),
        ],
    ),
    (
        'notifications', 'Notifications', 'mdi-bell-ring-outline',
        [
            ('view', 'View Notifications', 'View notifications'),
            ('update', 'Manage Notifications', 'Configure notification preferences'),
        ],
    ),
    (
        'billing', 'Billing & Usage', 'mdi-currency-usd',
        [
            ('view', 'View Billing', 'View billing and API usage'),
            ('export', 'Export Billing', 'Export billing data'),
        ],
    ),
    (
        'financing', 'Vehicle Financing', 'mdi-cash-multiple',
        [
            ('view', 'View Financing', 'View vehicle financing and loan data'),
            ('create', 'Create Financing', 'Create financing/loan records'),
            ('update', 'Edit Financing', 'Modify financing records'),
            ('delete', 'Delete Financing', 'Remove financing records'),
            ('approve', 'Approve Payments', 'Mark payments as paid/waived'),
        ],
    ),
    (
        'expenses', 'Expenses', 'mdi-receipt-text-outline',
        [
            ('view', 'View Expenses', 'View expense records'),
            ('create', 'Create Expenses', 'Create new expense records'),
            ('update', 'Edit Expenses', 'Modify expense records'),
            ('delete', 'Delete Expenses', 'Remove expense records'),
            ('approve', 'Approve Expenses', 'Approve or reject expense submissions'),
        ],
    ),
    (
        'reports', 'Reports & Analytics', 'mdi-chart-line',
        [
            ('view', 'View Reports', 'View financial and operational reports'),
            ('export', 'Export Reports', 'Export report data'),
        ],
    ),
    (
        'users', 'User Management', 'mdi-account-group',
        [
            ('view', 'View Users', 'View user directory'),
            ('create', 'Invite Users', 'Invite new users to the organization'),
            ('update', 'Edit Users', 'Modify user profiles and roles'),
            ('delete', 'Deactivate Users', 'Deactivate or remove users'),
            ('assign', 'Assign Roles', 'Assign roles to users'),
        ],
    ),
    (
        'settings', 'Settings', 'mdi-cog-outline',
        [
            ('view', 'View Settings', 'View organization settings'),
            ('update', 'Edit Settings', 'Modify organization settings'),
        ],
    ),
    (
        'dqf', 'Driver Qualification', 'mdi-account-check-outline',
        [
            ('view', 'View DQF', 'View driver qualification files'),
            ('create', 'Create DQF', 'Create DQF records'),
            ('update', 'Edit DQF', 'Modify DQF records'),
            ('delete', 'Delete DQF', 'Remove DQF records'),
        ],
    ),
    (
        'locations', 'Locations', 'mdi-map-marker-multiple',
        [
            ('view', 'View Locations', 'View locations and geofences'),
            ('create', 'Add Locations', 'Create new locations'),
            ('update', 'Edit Locations', 'Modify locations'),
            ('delete', 'Delete Locations', 'Remove locations'),
        ],
    ),
]

def _all_permission_codes():
    """Return a list of all (module, action) pairs from the registry."""
    codes = []
    for module, _label, _icon, actions in PERMISSIONS_REGISTRY:
        for action, _l, _d in actions:
            codes.append((module, action))
    return codes


# System roles seeded per tenant. Each role specifies a ``key``, ``name``,
# ``description``, Vuetify ``color``, MDI ``icon``, and the list of
# ``(module, action)`` permission codes to grant.
SYSTEM_ROLES = [
    {
        'key': 'admin',
        'name': 'Administrator',
        'description': 'Full access to all modules and settings. Can manage users, roles, and organizational configuration.',
        'color': '#error',
        'icon': 'mdi-shield-crown',
        'is_system': True,
        'is_default': False,
        'permissions': _all_permission_codes(),
    },
    {
        'key': 'manager',
        'name': 'Fleet Manager',
        'description': 'Manages day-to-day fleet operations. Full access to vehicles, drivers, dispatch, maintenance, fuel, and reports.',
        'color': '#primary',
        'icon': 'mdi-shield-account',
        'is_system': True,
        'is_default': False,
        'permissions': [
            # View everything
            *[(mod, 'view') for mod, _l, _i, _a in PERMISSIONS_REGISTRY],
            # Full CRUD on operational modules
            *[(mod, act) for mod, _l, _i, _a in PERMISSIONS_REGISTRY
              for act, _al, _ad in _a if act in ('view', 'create', 'update', 'delete', 'approve', 'assign', 'export')
              and mod not in ('settings', 'billing', 'users')],
            # Limited user management: view + assign
            ('users', 'view'),
            ('users', 'assign'),
            # Settings: view only
            ('settings', 'view'),
            ('billing', 'view'),
        ],
    },
    {
        'key': 'dispatcher',
        'name': 'Dispatcher',
        'description': 'Manages dispatch operations, assigns drivers and vehicles to jobs, and monitors live fleet movements.',
        'color': '#info',
        'icon': 'mdi-map-marker-radius',
        'is_system': True,
        'is_default': False,
        'permissions': [
            ('dispatch', 'view'), ('dispatch', 'create'), ('dispatch', 'update'), ('dispatch', 'assign'),
            ('transfers', 'view'), ('transfers', 'create'), ('transfers', 'update'), ('transfers', 'assign'),
            ('vehicles', 'view'), ('drivers', 'view'),
            ('telematics', 'view'),
            ('dispatch', 'delete'),
            ('contacts', 'view'),
            ('locations', 'view'),
            ('notifications', 'view'), ('notifications', 'update'),
        ],
    },
    {
        'key': 'mechanic',
        'name': 'Mechanic',
        'description': 'Handles maintenance, work orders, inspections, inventory, and tire management.',
        'color': '#warning',
        'icon': 'mdi-wrench',
        'is_system': True,
        'is_default': False,
        'permissions': [
            ('maintenance', 'view'), ('maintenance', 'create'), ('maintenance', 'update'), ('maintenance', 'approve'),
            ('inspections', 'view'), ('inspections', 'create'), ('inspections', 'update'),
            ('inventory', 'view'), ('inventory', 'create'), ('inventory', 'update'),
            ('tires', 'view'), ('tires', 'create'), ('tires', 'update'),
            ('vehicles', 'view'),
            ('garage', 'view'), ('garage', 'create'), ('garage', 'update'),
            ('recalls', 'view'), ('recalls', 'update'),
            ('reminders', 'view'), ('reminders', 'create'), ('reminders', 'update'),
            ('equipment', 'view'), ('equipment', 'update'),
            ('documents', 'view'), ('documents', 'create'),
        ],
    },
    {
        'key': 'driver',
        'name': 'Driver',
        'description': 'Limited access for drivers. View assigned vehicles andDispatch tasks, log fuel, and submit inspections.',
        'color': '#success',
        'icon': 'mdi-steering',
        'is_system': True,
        'is_default': True,
        'permissions': [
            ('vehicles', 'view'),
            ('dispatch', 'view'),
            ('transfers', 'view'),
            ('fuel', 'view'), ('fuel', 'create'),
            ('inspections', 'view'), ('inspections', 'create'),
            ('documents', 'view'),
            ('notifications', 'view'), ('notifications', 'update'),
            ('accidents', 'view'), ('accidents', 'create'),
        ],
    },
]
