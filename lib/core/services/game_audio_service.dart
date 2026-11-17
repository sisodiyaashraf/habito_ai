import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GameAudioService {
  static final GameAudioService _instance = GameAudioService._internal();
  factory GameAudioService() => _instance;
  GameAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  Future<void> init() async {
    try {
      final box = await Hive.openBox('settings');
      _isMuted = box.get('is_audio_muted', defaultValue: false);
    } catch (e) {
      debugPrint("GameAudioService init error: $e");
    }
  }

  void setMuted(bool muted) async {
    _isMuted = muted;
    try {
      final box = await Hive.openBox('settings');
      await box.put('is_audio_muted', muted);
    } catch (_) {}
  }

  Future<void> playBlip() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/neutral_blip.mp3'), volume: 0.6);
    } catch (e) {
      debugPrint("Audio play blip error: $e");
    }
  }

  Future<void> playChime() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/scratchonix-victory-chime-366449.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint("Audio play chime error: $e");
    }
  }

  Future<void> playSoftChime() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/soft_chime.mp3'), volume: 0.7);
    } catch (e) {
      debugPrint("Audio play soft chime error: $e");
    }
  }

  Future<void> playGlitch() async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/glitch_error.mp3'), volume: 0.6);
    } catch (e) {
      debugPrint("Audio play glitch error: $e");
    }
  }
}
