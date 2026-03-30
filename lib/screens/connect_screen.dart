import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart' as svc;
import '../theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  ConnectScreen — Triple-link connection (QR | Manual | USB)
// ════════════════════════════════════════════════════════════════════════════

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _ipCtrl   = TextEditingController();
  final _portCtrl = TextEditingController(text: '5050');
  bool _scanning  = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); _ipCtrl.dispose(); _portCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final conn  = context.watch<svc.ConnectivityService>();
    final state = conn.state;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AuraTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Logo / header ──────────────────────────────────────────
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (r) => AuraTheme.accentGradient.createShader(r),
                child: Text('AURA MONITOR', style: AuraTheme.orbitron(28, weight: FontWeight.w900)),
              ),
              Text('PRO  v1.0', style: AuraTheme.inter(12, color: AuraTheme.textSec)),
              const SizedBox(height: 36),

              // ── Status strip ───────────────────────────────────────────
              _StatusStrip(state, conn.lastError, conn.connectedUrl),
              const SizedBox(height: 28),

              // ── Tabs ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color:        AuraTheme.panelFill,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: AuraTheme.cyan.withAlpha(50)),
                  ),
                  child: TabBar(
                    controller: _tab,
                    tabs: const [
                      Tab(text: 'QR CODE'),
                      Tab(text: 'MANUAL IP'),
                      Tab(text: 'USB'),
                    ],
                    labelStyle:         AuraTheme.orbitron(11),
                    unselectedLabelStyle: AuraTheme.orbitron(11),
                    labelColor:         AuraTheme.cyan,
                    unselectedLabelColor: AuraTheme.textSec,
                    indicator:          BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color:        AuraTheme.cyan.withAlpha(30),
                      border:       Border.all(color: AuraTheme.cyan.withAlpha(120)),
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tab views ─────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _QrTab(onDetected: _onQr),
                    _ManualTab(_ipCtrl, _portCtrl, onConnect: _connectManual),
                    _UsbTab(onConnect: _connectUsb),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQr(String url) {
    if (_scanning) return;
    setState(() => _scanning = true);
    context.read<svc.ConnectivityService>().connectFromQr(url);
  }

  void _connectManual() {
    final ip   = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 5050;
    if (ip.isEmpty) return;
    context.read<svc.ConnectivityService>().connectManual(ip, port: port);
  }

  void _connectUsb() =>
      context.read<svc.ConnectivityService>().connectUsb();
}

// ── Status strip ──────────────────────────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final svc.ConnectionState state;
  final String? error;
  final String? url;

  const _StatusStrip(this.state, this.error, this.url);

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (state) {
      svc.ConnectionState.connected    => (AuraTheme.success, Icons.wifi,                'CONNECTED'),
      svc.ConnectionState.connecting   => (AuraTheme.warn,    Icons.wifi_find,           'CONNECTING…'),
      svc.ConnectionState.error        => (AuraTheme.danger,  Icons.wifi_off,            'ERROR'),
      svc.ConnectionState.disconnected => (AuraTheme.textSec, Icons.wifi_off,            'DISCONNECTED'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:        color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AuraTheme.orbitron(11, color: color)),
                  if (error != null)
                    Text(error!, style: AuraTheme.inter(11, color: AuraTheme.danger),
                        overflow: TextOverflow.ellipsis),
                  if (url != null && state == svc.ConnectionState.connected)
                    Text(url!, style: AuraTheme.inter(11, color: AuraTheme.textSec),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (state == svc.ConnectionState.connecting)
              SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, valueColor: AlwaysStoppedAnimation(color))),
          ],
        ),
      ),
    );
  }
}

// ── QR tab ─────────────────────────────────────────────────────────────────────
class _QrTab extends StatefulWidget {
  final ValueChanged<String> onDetected;
  const _QrTab({required this.onDetected});
  @override State<_QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<_QrTab> {
  bool _done = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        Text('Point camera at the QR code\ndisplayed in the server console.',
            textAlign: TextAlign.center,
            style: AuraTheme.inter(14, color: AuraTheme.textSec)),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              onDetect: (capture) {
                if (_done) return;
                final url = capture.barcodes.firstOrNull?.rawValue;
                if (url != null && url.startsWith('ws://')) {
                  setState(() => _done = true);
                  widget.onDetected(url);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

// ── Manual IP tab ─────────────────────────────────────────────────────────────
class _ManualTab extends StatelessWidget {
  final TextEditingController ipCtrl;
  final TextEditingController portCtrl;
  final VoidCallback onConnect;

  const _ManualTab(this.ipCtrl, this.portCtrl, {required this.onConnect});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      children: [
        Text('Enter your PC\'s local IP address.',
            style: AuraTheme.inter(14, color: AuraTheme.textSec)),
        const SizedBox(height: 28),
        _Field(ctrl: ipCtrl, hint: '192.168.1.100', label: 'IP ADDRESS',
            keyboardType: TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 16),
        _Field(ctrl: portCtrl, hint: '5050', label: 'PORT',
            keyboardType: TextInputType.number),
        const SizedBox(height: 32),
        _GlowButton('CONNECT', AuraTheme.cyan, onConnect),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, label;
  final TextInputType? keyboardType;

  const _Field({required this.ctrl, required this.hint, required this.label, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AuraTheme.orbitron(10, color: AuraTheme.textSec)),
      const SizedBox(height: 6),
      TextField(
        controller:   ctrl,
        keyboardType: keyboardType,
        style:        AuraTheme.orbitron(15, color: AuraTheme.cyan),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: AuraTheme.orbitron(15, color: AuraTheme.textSec),
          filled:    true,
          fillColor: AuraTheme.panelFill,
          border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AuraTheme.cyan.withAlpha(60)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AuraTheme.cyan),
          ),
        ),
      ),
    ],
  );
}

// ── USB tab ───────────────────────────────────────────────────────────────────
class _UsbTab extends StatelessWidget {
  final VoidCallback onConnect;
  const _UsbTab({required this.onConnect});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      children: [
        const Icon(Icons.usb, color: AuraTheme.orange, size: 48),
        const SizedBox(height: 16),
        Text(
          '1. Connect USB cable to PC\n2. Enable USB Tethering in phone settings\n3. Tap Connect — app will scan gateway IPs',
          textAlign: TextAlign.center,
          style: AuraTheme.inter(14, color: AuraTheme.textSec, weight: FontWeight.w400),
        ),
        const SizedBox(height: 32),
        _GlowButton('CONNECT VIA USB', AuraTheme.orange, onConnect),
      ],
    ),
  );
}

// ── Shared neon button ────────────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color:        color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withAlpha(180), width: 1.5),
        boxShadow:    AuraTheme.neonGlow(color),
      ),
      child: Center(
        child: Text(label, style: AuraTheme.orbitron(14, color: color)),
      ),
    ),
  );
}
