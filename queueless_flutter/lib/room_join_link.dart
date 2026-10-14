/// Builds the public customer URL for a queue room.
///
/// The optional compile-time base URL is intended for a deployed web host:
/// `--dart-define=QUEUELESS_PUBLIC_BASE_URL=https://example.test`. When it is
/// not provided, the browser's current origin is used, which keeps local
/// development local and avoids claiming that localhost is publicly reachable.
const _configuredPublicBaseUrl = String.fromEnvironment(
  'QUEUELESS_PUBLIC_BASE_URL',
);

const _staffRouteSegments = {'admin', 'dashboard', 'staff'};

String _safeConfiguredCustomerPath(Uri baseUri) {
  final path = baseUri.path;
  if (path.isEmpty || path == '/') return '';

  // A configured customer subpath is useful when the web app is hosted below
  // the domain root. Never carry a staff route into a customer QR payload.
  final hasStaffRoute = baseUri.pathSegments.any(
    (segment) => _staffRouteSegments.contains(segment.toLowerCase()),
  );
  return hasStaffRoute ? '' : path;
}

String? buildRoomJoinUrl({
  required int? roomId,
  String? baseUrl,
}) {
  if (roomId == null || roomId <= 0) return null;

  final configuredBase = (baseUrl ?? _configuredPublicBaseUrl).trim();
  final useCurrentOrigin = configuredBase.isEmpty;
  final baseUri = useCurrentOrigin
      ? Uri.base
      : Uri.tryParse(configuredBase);

  if (baseUri == null ||
      (baseUri.scheme != 'http' && baseUri.scheme != 'https') ||
      baseUri.host.isEmpty) {
    return null;
  }

  // Build a fresh URI instead of replacing only the query. This deliberately
  // excludes user info, inherited query parameters, and fragments. The
  // current-origin fallback always starts at the app root; only an explicitly
  // configured, non-staff customer subpath may be retained.
  return Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.port,
    path: useCurrentOrigin ? '' : _safeConfiguredCustomerPath(baseUri),
    queryParameters: {'roomId': '$roomId'},
  ).toString();
}
