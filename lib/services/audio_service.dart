import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String? _audioPath;

  Future<void> startRecording() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/recording.aac';
    await _audioRecorder.openRecorder();
    await _audioRecorder.startRecorder(toFile: path);
    _audioPath = path;
  }

  Future<void> stopRecording() async {
    await _audioRecorder.stopRecorder();
  }

  Future<void> playRecording() async {
    if (_audioPath != null) {
      await _audioPlayer.openPlayer();
      await _audioPlayer.startPlayer(fromURI: _audioPath!);
    }
  }

  String? get audioPath => _audioPath;
}
