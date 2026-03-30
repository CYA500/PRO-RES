// ─── models/sensor_model.dart ─────────────────────────────────────────────────

/// Describes a sensor available on the PC (sent once on connect).
class SensorDescriptor {
  final String id;
  final String category;
  final String name;
  final String unit;
  final double minVal;
  final double maxVal;

  const SensorDescriptor({
    required this.id,
    required this.category,
    required this.name,
    required this.unit,
    required this.minVal,
    required this.maxVal,
  });

  factory SensorDescriptor.fromJson(Map<String, dynamic> j) => SensorDescriptor(
        id:       j['id']       as String,
        category: j['category'] as String,
        name:     j['name']     as String,
        unit:     j['unit']     as String? ?? '',
        minVal:   (j['minVal']  as num?)?.toDouble() ?? 0.0,
        maxVal:   (j['maxVal']  as num?)?.toDouble() ?? 100.0,
      );
}

/// A live reading for one sensor.
class SensorReading {
  final String id;
  final double value;
  final int    ts;

  const SensorReading({required this.id, required this.value, required this.ts});

  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        id:    j['id']    as String,
        value: (j['value'] as num).toDouble(),
        ts:    j['ts']    as int,
      );
}

/// Tracks live state for a single metric card on the dashboard.
class DashboardMetric {
  final SensorDescriptor descriptor;
  double  currentValue;
  double  peakValue;
  double  avgValue;
  int     sampleCount;
  final List<double> history; // last N samples for sparkline

  static const int maxHistory = 60;

  DashboardMetric({required this.descriptor})
      : currentValue = 0,
        peakValue    = 0,
        avgValue     = 0,
        sampleCount  = 0,
        history      = [];

  void push(double v) {
    currentValue = v;
    if (v > peakValue) peakValue = v;
    sampleCount++;
    avgValue = avgValue + (v - avgValue) / sampleCount;
    history.add(v);
    if (history.length > maxHistory) history.removeAt(0);
  }

  /// Normalised 0-1 value for gauge rendering.
  double get normalized {
    final range = descriptor.maxVal - descriptor.minVal;
    if (range <= 0) return 0;
    return ((currentValue - descriptor.minVal) / range).clamp(0.0, 1.0);
  }
}
