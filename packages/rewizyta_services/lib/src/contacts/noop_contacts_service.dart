import 'package:rewizyta_services/src/contacts/contacts_service.dart';

final class const NoopContactsService() implements ContactsService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<PickedContact?> pickContact() async => null;
}
