import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_model.dart';
import '../theme.dart';
import 'circular_gauge.dart';

// ════════════════════════════════════════════════════════════════════════════
//  MetricCard — translucent panel with gauge, sparkline, peak/avg
// ════════════════════════════════════════════════════════════════════════════

class MetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final VoidCallback     onRemove;

  const MetricCard({super.key, required this.metric, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final d     = metric.descriptor;
    final color = AuraTheme.gaugeColor(metric.normalized);

    return Dismissible(
      key: ValueKey(d.id),
      direction: DismissDirection.endToStart,
      background: _dismissBg(),
      onDismissed: (_) => onRemove(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AuraTheme.glowBorder(color),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  _CategoryBadge(d.category),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.name,
                        style: AuraTheme.orbitron(13, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _WarningIcon(metric.normalized),
                ],
              ),
              const SizedBox(height: 14),

              // ── Gauge row ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularGauge(
                    value:        metric.normalized,
                    displayValue: metric.currentValue,
                    unit:         d.unit,
                    label:        d.name,
                    size:         96,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow('PEAK',  metric.peakValue, d.unit, color),
                        const SizedBox(height: 6),
                        _StatRow('AVG',   metric.avgValue,  d.unit, AuraTheme.textSec),
                        const SizedBox(height: 12),
                        // ── Mini sparkline ─────────────────────────────
                        if (metric.history.length > 2)
                          SizedBox(height: 40, child: _Sparkline(metric, color)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissBg() => Container(
    alignment: Alignment.centerRight,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color:        AuraTheme.danger.withAlpha(40),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: AuraTheme.danger.withAlpha(120)),
    ),
    padding: const EdgeInsets.only(right: 24),
    child: const Icon(Icons.delete_outline, color: AuraTheme.danger, size: 28),
  );
}

// ── Stat row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color  color;

  const _StatRow(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: AuraTheme.inter(10, color: AuraTheme.textSec)),
      const SizedBox(width: 6),
      Text(_fmt(value),
          style: AuraTheme.orbitron(14, weight: FontWeight.w700, color: color)),
      const SizedBox(width: 4),
      Text(unit, style: AuraTheme.inter(10, color: AuraTheme.textSec)),
    ],
  );

  static String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}G';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
  }
}

// ── Sparkline (fl_chart LineChart) ────────────────────────────────────────────
class _Sparkline extends StatelessWidget {
  final DashboardMetric metric;
  final Color           color;

  const _Sparkline(this.metric, this.color);

  @override
  Widget build(BuildContext context) {
    final spots = metric.history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData:         const FlGridData(show: false),
        titlesData:       const FlTitlesData(show: false),
        borderData:       FlBorderData(show: false),
        lineTouchData:    const LineTouchData(enabled: false),
        minY: metric.descriptor.minVal,
        maxY: metric.descriptor.maxVal > 0 ? metric.descriptor.maxVal : null,
        lineBarsData: [
          LineChartBarData(
            spots:              spots,
            isCurved:           true,
            color:              color,
            barWidth:           1.5,
            dotData:            const FlDotData(show: false),
            belowBarData:       BarAreaData(
              show:   true,
              color:  color.withAlpha(30),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 150),
    );
  }
}

// ── Category badge ────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(category.split(' ').first,
              style: AuraTheme.inter(9, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  static (Color, IconData) _style(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('processor') || c.contains('cpu')) return (AuraTheme.cyan,   Icons.memory);
    if (c.contains('memory')    || c.contains('ram')) return (AuraTheme.purple, Icons.storage);
    if (c.contains('disk'))                           return (AuraTheme.orange, Icons.disc_full);
    if (c.contains('network'))                        return (AuraTheme.success,Icons.wifi);
    if (c.contains('gpu'))                            return (AuraTheme.warn,   Icons.videogame_asset);
    if (c.contains('thermal'))                        return (AuraTheme.danger, Icons.thermostat);
    return (AuraTheme.textSec, Icons.sensors);
  }
}

// ── Warning icon at high load ─────────────────────────────────────────────────
class _WarningIcon extends StatelessWidget {
  final double normalized;
  const _WarningIcon(this.normalized);

  @override
  Widget build(BuildContext context) {
    if (normalized < 0.9) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Icon(Icons.warning_amber_rounded, color: AuraTheme.danger, size: 18),
    );
  }
}
