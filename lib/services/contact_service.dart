import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  Future<List<Contact>> getContacts() async {
    if (await Permission.contacts.isGranted) {
      return await FlutterContacts.getContacts(withProperties: true);
    } else {
      await Permission.contacts.request();
      return [];
    }
  }
}
