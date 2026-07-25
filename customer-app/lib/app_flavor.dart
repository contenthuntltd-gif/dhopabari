/// Which build this is — set at compile time with
/// `--dart-define=APP_FLAVOR=admin` (or `rider`). Defaults to the customer
/// app. Drives the launch screen in [main] so the same codebase ships as
/// three separate APKs (customer / admin / rider).
const appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'customer');

bool get isAdminApp => appFlavor == 'admin';
bool get isRiderApp => appFlavor == 'rider';
bool get isCustomerApp => appFlavor == 'customer';
