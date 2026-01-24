import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = true;
  double _volume = 0.3;
  String _currentTrack = "music1.mp3";

  final List<String> tracks = ["music1.mp3", "music2.mp3", "music3.mp3"];

  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  String get currentTrack => _currentTrack;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {}

  Future<void> _playMusic() async {
    try {
      // Eğer dosya yoksa burası hata verebilir, o yüzden try-catch bloğunda
      await _player.play(AssetSource('music/$_currentTrack'));
    } catch (e) {
      debugPrint("Dosya bulunamadı veya oynatılamadı: $e");
      _isPlaying = false; // Müzik çalamadığı için durduruldu olarak işaretle
      notifyListeners();
    }
  }

  void togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      _isPlaying = !_isPlaying;
      notifyListeners();
    } catch (e) {
      debugPrint("Oynatma/Durdurma hatası: $e");
    }
  }

  void setVolume(double vol) {
    _volume = vol;
    _player.setVolume(vol);
    notifyListeners();
  }

  Future<void> changeTrack(String trackName) async {
    if (_currentTrack == trackName) return;
    _currentTrack = trackName;

    // Eğer müzik açıksa yeni parçaya geç
    if (_isPlaying) {
      try {
        await _player.stop();
        await _playMusic();
      } catch (e) {
        debugPrint("Parça değiştirme hatası: $e");
      }
    }
    notifyListeners();
  }
}
