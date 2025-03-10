import 'package:flutter/material.dart';
import 'package:capi/models/call_history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capi/services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  final List<CallHistory> callHistory;

  HistoryScreen({required this.callHistory});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchHistory);
  }

  void _searchHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      widget.callHistory.forEach((history) {
        final isMatch = history.phoneNumber.toLowerCase().contains(query) ||
            history.type.toLowerCase().contains(query);
        history.isFlagged = isMatch;
      });
    });
  }

  void _unflagNumber(String phoneNumber) {
    setState(() {
      final history = widget.callHistory.firstWhere(
        (hist) => hist.phoneNumber == phoneNumber,
      );

      history.isFlagged = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call History'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    HistorySearchDelegate(widget.callHistory, _unflagNumber),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getCallHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final callHistory = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: callHistory.length,
                  itemBuilder: (context, index) {
                    final history = callHistory[index];
                    final data = history.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['phoneNumber']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Type: ${data['type']} - ${data['timestamp'].toDate()}'),
                          if (data['message'] != null)
                            Text('Message: ${data['message']}'),
                          if (data['voiceNotePath'] != null)
                            Text('Voice Note: Available'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data['isFlagged'])
                            IconButton(
                              icon: Icon(Icons.flag, color: Colors.red),
                              onPressed: () async {
                                await _firestoreService.updateFlaggedStatus(
                                    history.id, false);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HistorySearchDelegate extends SearchDelegate<String> {
  final List<CallHistory> callHistory;
  final Function(String) onUnflag;

  HistorySearchDelegate(this.callHistory, this.onUnflag);

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
    final results = callHistory
        .where((history) =>
            history.phoneNumber.toLowerCase().contains(query.toLowerCase()) ||
            history.type.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final history = results[index];
        return ListTile(
          title: Text('${history.phoneNumber} - ${history.displayName}'),
          subtitle: Text('Type: ${history.type} - ${history.timestamp}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (history.isFlagged)
                IconButton(
                  icon: Icon(Icons.flag, color: Colors.red),
                  onPressed: () => onUnflag(history.phoneNumber),
                ),
            ],
          ),
        );
      },
    );
  }
}
