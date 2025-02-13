import 'package:flutter/material.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';

void launchCall(String callNumber, BuildContext context) async {
  await FlutterDirectCallerPlugin.callNumber(callNumber);
}
