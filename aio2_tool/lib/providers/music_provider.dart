import 'package:flutter/material.dart';

/// Müzik kaldırıldı – stub provider (mevcut kodlar kırılmasın).
class MusicProvider extends ChangeNotifier {
  bool get isPlaying => false;
  double get volume => 0;
  String get currentTrack => '';
  List<String> get tracks => [];

  void togglePlay() {}
  void setVolume(double vol) {}
  Future<void> changeTrack(String trackName) async {}
}
