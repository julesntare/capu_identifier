class CallHistory {
  final String? displayName;
  final String phoneNumber;
  final String type; // 'call', 'text', 'voice_note'
  final String? message;
  final String? voiceNotePath;
  final DateTime timestamp;
  bool isFlagged;

  CallHistory({
    this.displayName,
    required this.phoneNumber,
    required this.type,
    this.message,
    this.voiceNotePath,
    required this.timestamp,
    this.isFlagged = false,
  });
}
