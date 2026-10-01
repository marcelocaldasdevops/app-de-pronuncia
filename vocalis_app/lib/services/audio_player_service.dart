import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  double _currentSpeed = 1.0;
  bool _isLooping = false;

  AudioPlayer get player => _player;
  double get currentSpeed => _currentSpeed;
  bool get isLooping => _isLooping;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  AudioPlayerService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
    if (_currentSpeed != 1.0) {
      await _player.setPlaybackRate(_currentSpeed);
    }
  }

  Future<void> playBytes(List<int> bytes, {String mimeType = 'audio/wav'}) async {
    await _player.stop();
    final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    // mimeType explícito é obrigatório na camada Web para evitar que o plugin assuma 'audio/mpeg'
    await _player.play(BytesSource(uint8, mimeType: mimeType));
    if (_currentSpeed != 1.0) {
      await _player.setPlaybackRate(_currentSpeed);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _player.setPlaybackRate(speed);
  }

  Future<void> toggleLoop() async {
    _isLooping = !_isLooping;
    await _player.setReleaseMode(_isLooping ? ReleaseMode.loop : ReleaseMode.stop);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
