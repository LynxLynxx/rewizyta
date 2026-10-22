/// Every path in one place; screens never hard-code a string.
abstract final class RoutePaths() {
  static const clients = '/clients';
  static const clientNew = '/clients/new';

  static String clientDetailFor(String id) => '/clients/$id';

  static String clientEditFor(String id) => '/clients/$id/edit';
}
