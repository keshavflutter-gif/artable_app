/// In-memory studio flow state (mirrors sessionStorage in doc/js/app.js).
class StudioSession {
  StudioSession._();
  static final StudioSession instance = StudioSession._();

  String recordedDuration = '0:42';
  String? selectedMusic;

  void resetRecording() {
    recordedDuration = '0:00';
  }
}
