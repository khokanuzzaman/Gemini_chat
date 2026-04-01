import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../constants/app_strings.dart';
import '../errors/exceptions.dart';

class VoiceRecorderService {
  VoiceRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw const PermissionDeniedException(AppStrings.micPermissionSettings);
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(_recordConfig, path: path);
    _currentPath = path;
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    final recordedPath = path ?? _currentPath;
    _currentPath = null;
    return recordedPath;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

const _recordConfig = RecordConfig(
  encoder: AudioEncoder.aacLc,
  sampleRate: 16000,
  bitRate: 128000,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
);
