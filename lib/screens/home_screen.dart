import 'package:capi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:capi/services/contact_service.dart';
import 'package:capi/services/notification_service.dart';
import 'package:capi/services/audio_service.dart';
import 'package:capi/services/call_service.dart';
import 'package:capi/models/call_history_model.dart';
import 'package:capi/screens/history_screen.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:capi/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContactService _contactService = ContactService();
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();
  final CallService _callService = CallService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isRecording = false;
  List<CallHistory> _callHistory = [];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactService.getContacts();
    setState(() {
      _contacts = contacts;
      _filteredContacts = contacts;
    });
  }

  void _searchContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showCallOptionsDialog(
      BuildContext context, Contact contact) async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Call Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Send Text Message'),
                onTap: () => Navigator.pop(context, 'text'),
              ),
              ListTile(
                title: Text('Send Voice Note'),
                onTap: () => Navigator.pop(context, 'voice'),
              ),
              ListTile(
                title: Text('Call Directly'),
                onTap: () => Navigator.pop(context, 'call'),
              ),
            ],
          ),
        );
      },
    );

    if (option == 'text') {
      final message = await showDialog<String>(
        context: context,
        builder: (context) {
          String? message;
          return AlertDialog(
            title: Text('Send Message'),
            content: TextField(
              onChanged: (value) => message = value,
              decoration: InputDecoration(hintText: 'Enter your message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, message),
                child: Text('Send'),
              ),
            ],
          );
        },
      );

      if (message != null && message.isNotEmpty) {
        await _firestoreService.saveCallHistory(
          phoneNumber: contact.phones.first.number,
          type: 'text',
          message: message,
          timestamp: DateTime.now(),
        );
        _notificationService.showNotification(
            'Message Sent', 'Message sent to ${contact.displayName}');
        _callService.launchCall(contact.phones.first.number);
      }
    } else if (option == 'voice') {
      await _audioService.startRecording();
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Recording'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: () async {
                    print(_audioService.audioPath);
                    if (_isRecording) {
                      await _audioService.stopRecording();
                      Navigator.pop(context);
                    } else {
                      await _audioService.startRecording();
                    }
                  },
                ),
                if (_audioService.audioPath != null)
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: _audioService.playRecording,
                  ),
              ],
            ),
          );
        },
      );

      if (_audioService.audioPath != null) {
        await _firestoreService.saveCallHistory(
          phoneNumber: contact.phones.first.number,
          type: 'voice_note',
          voiceNotePath: _audioService.audioPath,
          timestamp: DateTime.now(),
        );
        _notificationService.showNotification(
            'Voice Note Sent', 'Voice note sent to ${contact.displayName}');
        _callService.launchCall(contact.phones.first.number);
      }
    } else if (option == 'call') {
      await _firestoreService.saveCallHistory(
        phoneNumber: contact.phones.first.number,
        type: 'call',
        timestamp: DateTime.now(),
      );
      _notificationService.showNotification(
          'Call Initiated', 'Calling ${contact.displayName}');
      _callService.launchCall(contact.phones.first.number);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoryScreen(callHistory: _callHistory),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(
                  _contacts,
                  _searchContacts,
                  (phoneNumber) async {
                    _callHistory.add(CallHistory(
                      phoneNumber: phoneNumber,
                      type: 'call',
                      timestamp: DateTime.now(),
                      isFlagged: true,
                    ));
                    _notificationService.showNotification('Call Flagged',
                        'Call from $phoneNumber has been flagged.');
                  },
                  _showCallOptionsDialog,
                ),
              );
            },
          ),
        ],
      ),
      body: _filteredContacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                Contact contact = _filteredContacts[index];
                return ListTile(
                  title: Text(
                    contact.displayName,
                    style: TextStyle(
                      color: contact.phones.isNotEmpty &&
                              _callHistory.any((history) =>
                                  history.phoneNumber ==
                                      contact.phones.first.number &&
                                  history.isFlagged)
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                  subtitle: Text(contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () async {
                          await _showCallOptionsDialog(context, contact);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.flag,
                          color: contact.phones.isNotEmpty &&
                                  _callHistory.any((history) =>
                                      history.phoneNumber ==
                                          contact.phones.first.number &&
                                      history.isFlagged)
                              ? Colors.red
                              : Colors.black,
                        ),
                        onPressed: () async {
                          _callHistory.add(CallHistory(
                            phoneNumber: contact.phones.first.number,
                            type: 'call',
                            timestamp: DateTime.now(),
                            isFlagged: true,
                          ));
                          _notificationService.showNotification('Call Flagged',
                              'Call from ${contact.displayName} has been flagged.');
                          setState(() {}); // Refresh the UI
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ContactSearchDelegate extends SearchDelegate<String> {
  final List<Contact> contacts;
  final Function(String) onSearch;
  final Function(String) onFlag;
  final Function(BuildContext, Contact) onCall;

  ContactSearchDelegate(this.contacts, this.onSearch, this.onFlag, this.onCall);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = contacts
        .where((contact) =>
            contact.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        Contact contact = results[index];
        return ListTile(
          title: Text(contact.displayName),
          subtitle: Text(
              contact.phones.isNotEmpty ? contact.phones.first.number : ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.call),
                onPressed: () async {
                  await onCall(context, contact);
                },
              ),
              IconButton(
                icon: Icon(Icons.flag),
                onPressed: () async {
                  onFlag(contact.phones.first.number);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
