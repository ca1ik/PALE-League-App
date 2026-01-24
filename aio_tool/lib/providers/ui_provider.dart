import 'package:flutter/material.dart';

class UIProvider extends ChangeNotifier {
  bool _isModernSidebar = false;
  bool _isSpatialMode = false; // YENİ: Spatial Mod Kontrolü

  bool get isModernSidebar => _isModernSidebar;
  bool get isSpatialMode => _isSpatialMode; // Getter

  void toggleSidebarStyle() {
    _isModernSidebar = !_isModernSidebar;
    notifyListeners();
  }

  // Modu değiştiren fonksiyon
  void toggleSpatialMode() {
    _isSpatialMode = !_isSpatialMode;
    notifyListeners();
  }
}
