/// Every path in one place; screens never hard-code a string.
abstract final class RoutePaths() {
  static const clients = '/clients';
  static const clientDetail = '/clients/:id';

  static String clientDetailFor(String id) => '/clients/$id';
}
