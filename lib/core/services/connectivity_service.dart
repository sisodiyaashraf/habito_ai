import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _isOnline = _checkStatus(results);
      _controller.add(_isOnline);

      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final bool newStatus = _checkStatus(results);
        if (_isOnline != newStatus) {
          _isOnline = newStatus;
          _controller.add(_isOnline);
        }
      });
    } catch (e) {
      debugPrint("Connectivity Error: $e");
      // Default to online to avoid blocking features if plugin fails
      _isOnline = true; 
      _controller.add(true);
    }
  }

  bool _checkStatus(List<ConnectivityResult> results) {
    // Return false only if it's explicitly 'none'
    return !results.contains(ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}
