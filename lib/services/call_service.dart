import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';

class CallService {
  Future<void> launchCall(String callNumber) async {
    await FlutterDirectCallerPlugin.callNumber(callNumber);
  }
}
