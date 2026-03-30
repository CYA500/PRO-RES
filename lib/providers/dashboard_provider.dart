import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../models/sensor_model.dart';
import '../services/connectivity_service.dart';

/// Owns the active dashboard metrics and routes live readings to them.
class DashboardProvider extends ChangeNotifier {
  final ConnectivityService _conn;

  // ── Available sensors (from server catalogue) ──────────────────────────────
  List<SensorDescriptor> availableSensors = [];

  // ── Active dashboard cards (user-selected subset) ─────────────────────────
  final List<DashboardMetric> activeMetrics = [];

  // ── Command feedback ───────────────────────────────────────────────────────
  String? lastCommandResult;

  StreamSubscription? _catSub;
  StreamSubscription? _readSub;
  StreamSubscription? _cmdSub;

  DashboardProvider(this._conn) {
    _catSub  = _conn.catalogueStream.listen(_onCatalogue);
    _readSub = _conn.readingsStream.listen(_onReadings);
    _cmdSub  = _conn.cmdResultStream.listen(_onCmdResult);
  }

  // ─── Catalogue handler ─────────────────────────────────────────────────────
  void _onCatalogue(List<SensorDescriptor> list) {
    availableSensors = list;

    // Auto-add top CPU / RAM / Disk / Network cards if empty
    if (activeMetrics.isEmpty) {
      for (final pref in ['CPU', 'RAM', 'Disk', 'Net', 'GPU']) {
        final match = list.where((s) =>
            s.name.toUpperCase().contains(pref) &&
            !activeMetrics.any((m) => m.descriptor.id == s.id));
        if (match.isNotEmpty) addMetric(match.first);
        if (activeMetrics.length >= 6) break;
      }
    }

    notifyListeners();
  }

  // ─── Readings handler ──────────────────────────────────────────────────────
  void _onReadings(List<SensorReading> readings) {
    bool changed = false;
    for (final reading in readings) {
      for (final metric in activeMetrics) {
        if (metric.descriptor.id == reading.id) {
          final prev = metric.normalized;
          metric.push(reading.value);
          // Haptic buzz when crossing 90% threshold
          if (prev < 0.9 && metric.normalized >= 0.9) {
            _buzz();
          }
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  // ─── Command result ────────────────────────────────────────────────────────
  void _onCmdResult(Map<String, dynamic> data) {
    lastCommandResult = data['message'] as String? ?? '';
    notifyListeners();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  void addMetric(SensorDescriptor d) {
    if (activeMetrics.any((m) => m.descriptor.id == d.id)) return;
    activeMetrics.add(DashboardMetric(descriptor: d));
    notifyListeners();
  }

  void removeMetric(String id) {
    activeMetrics.removeWhere((m) => m.descriptor.id == id);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = activeMetrics.removeAt(oldIndex);
    activeMetrics.insert(newIndex, item);
    notifyListeners();
  }

  void sendCommand(String cmd, [Map<String, String>? args]) {
    lastCommandResult = null;
    _conn.sendCommand(cmd, args);
  }

  static Future<void> _buzz() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 60, amplitude: 180);
    }
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _readSub?.cancel();
    _cmdSub?.cancel();
    super.dispose();
  }
}
