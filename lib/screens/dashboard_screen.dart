import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/connectivity_service.dart';
import '../theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/add_metric_sheet.dart';

// ════════════════════════════════════════════════════════════════════════════
//  DashboardScreen — Dynamic live monitoring dashboard
// ════════════════════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;
  bool _cmdPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final conn = context.watch<ConnectivityService>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AuraTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(conn: conn, pulse: _pulse, onDisconnect: () => conn.disconnect()),
              Expanded(
                child: dash.activeMetrics.isEmpty
                    ? _EmptyState()
                    : ReorderableListView.builder(
                        padding:          const EdgeInsets.only(top: 4, bottom: 120),
                        onReorder:        dash.reorder,
                        proxyDecorator:   _proxyDecor,
                        itemCount:        dash.activeMetrics.length,
                        itemBuilder: (_, i) {
                          final metric = dash.activeMetrics[i];
                          return MetricCard(
                            key:      ValueKey(metric.descriptor.id),
                            metric:   metric,
                            onRemove: () => dash.removeMetric(metric.descriptor.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── FABs ─────────────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Commands panel
            _FabButton(
              icon:  Icons.terminal_rounded,
              color: AuraTheme.orange,
              label: 'COMMANDS',
              onTap: () => setState(() => _cmdPanelOpen = !_cmdPanelOpen),
            ),
            // Add metric
            _FabButton(
              icon:  Icons.add_circle_outline,
              color: AuraTheme.cyan,
              label: 'ADD METRIC',
              onTap: () => AddMetricSheet.show(context),
            ),
          ],
        ),
      ),

      // ── Command panel (slides up from bottom) ─────────────────────────
      bottomSheet: _cmdPanelOpen
          ? _CommandPanel(
              dash:    dash,
              onClose: () => setState(() => _cmdPanelOpen = false),
            )
          : null,
    );
  }

  Widget _proxyDecor(Widget child, int _, Animation<double> anim) =>
      AnimatedBuilder(
        animation: anim,
        builder:   (_, c) => Transform.scale(scale: 1.03, child: c),
        child:     child,
      );
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ConnectivityService conn;
  final Animation<double>   pulse;
  final VoidCallback         onDisconnect;

  const _TopBar({required this.conn, required this.pulse, required this.onDisconnect});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
            width:  8, height: 8,
            decoration: BoxDecoration(
              shape:     BoxShape.circle,
              color:     AuraTheme.success,
              boxShadow: [BoxShadow(
                color:      AuraTheme.success.withAlpha((pulse.value * 200).toInt()),
                blurRadius: 8 * pulse.value,
                spreadRadius: 1,
              )],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conn.hostName.isNotEmpty ? conn.hostName : 'CONNECTED',
                  style: AuraTheme.orbitron(14, weight: FontWeight.w700)),
              if (conn.hostOs.isNotEmpty)
                Text(conn.hostOs, style: AuraTheme.inter(10, color: AuraTheme.textSec),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          icon:    const Icon(Icons.logout_rounded, color: AuraTheme.danger, size: 22),
          onPressed: () {
            onDisconnect();
            Navigator.of(context).pop();
          },
          tooltip: 'Disconnect',
        ),
      ],
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sensors_off, color: AuraTheme.textSec.withAlpha(100), size: 56),
        const SizedBox(height: 16),
        Text('NO METRICS ADDED', style: AuraTheme.orbitron(14, color: AuraTheme.textSec)),
        const SizedBox(height: 8),
        Text('Tap  ADD METRIC  to start monitoring',
            style: AuraTheme.inter(13, color: AuraTheme.textSec)),
      ],
    ),
  );
}

// ── FAB button ────────────────────────────────────────────────────────────────
class _FabButton extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label;
  final VoidCallback onTap;

  const _FabButton({required this.icon, required this.color,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
        border:       Border.all(color: color.withAlpha(160), width: 1.5),
        boxShadow:    AuraTheme.neonGlow(color, spread: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AuraTheme.orbitron(11, color: color)),
        ],
      ),
    ),
  );
}

// ── Command Panel ─────────────────────────────────────────────────────────────
class _CommandPanel extends StatelessWidget {
  final DashboardProvider dash;
  final VoidCallback       onClose;

  const _CommandPanel({required this.dash, required this.onClose});

  static const _cmds = [
    (icon: Icons.sports_esports, label: 'GAME MODE ON',  color: AuraTheme.cyan,    cmd: 'gamemode',    args: null),
    (icon: Icons.games_outlined,  label: 'GAME MODE OFF', color: AuraTheme.textSec, cmd: 'gamemodeoff', args: null),
    (icon: Icons.memory,          label: 'FLUSH RAM',     color: AuraTheme.purple,  cmd: 'memoryflush', args: null),
    (icon: Icons.bolt,            label: 'HIGH PERF',     color: AuraTheme.warn,    cmd: 'powerplan',   args: {'plan': 'high'}),
    (icon: Icons.balance,         label: 'BALANCED',      color: AuraTheme.success, cmd: 'powerplan',   args: {'plan': 'balanced'}),
    (icon: Icons.power_settings_new, label: 'SHUTDOWN',   color: AuraTheme.danger,  cmd: 'shutdown',    args: {'mode': 'shutdown'}),
    (icon: Icons.restart_alt,     label: 'RESTART',       color: AuraTheme.orange,  cmd: 'shutdown',    args: {'mode': 'restart'}),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color:        Color(0xFF0D1117),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      border:       Border(top: BorderSide(color: AuraTheme.orange, width: 1)),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('DEEP COMMANDS', style: AuraTheme.orbitron(14, color: AuraTheme.orange)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AuraTheme.textSec, size: 20),
              onPressed: onClose,
            ),
          ],
        ),
        if (dash.lastCommandResult != null)
          Container(
            margin:   const EdgeInsets.only(bottom: 12),
            padding:  const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        AuraTheme.success.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: AuraTheme.success.withAlpha(80)),
            ),
            child: Text(dash.lastCommandResult!,
                style: AuraTheme.inter(12, color: AuraTheme.success)),
          ),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            for (final c in _cmds)
              GestureDetector(
                onTap: () {
                  final args = c.args != null
                      ? Map<String, String>.from(c.args! as Map)
                      : null;
                  dash.sendCommand(c.cmd, args);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:        (c.color as Color).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: (c.color as Color).withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon as IconData, color: c.color as Color, size: 16),
                      const SizedBox(width: 8),
                      Text(c.label as String,
                          style: AuraTheme.orbitron(10, color: c.color as Color)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
