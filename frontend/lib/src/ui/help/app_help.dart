import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

const experimentalNotice =
    'For fun, learning and experimentation only. FlutBeat is not a medical device and cannot replace a medical ECG or professional medical advice. Do not use it to diagnose, monitor or treat a medical condition.';

class ElectrodeGuide extends StatelessWidget {
  const ElectrodeGuide({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Electrode placement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Front view: your right is on the left of this picture.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Semantics(
            label: 'RA green on your upper right chest, LA red on your upper left chest, both below the collarbone. RL yellow on your lower right torso, reference electrode.',
            child: const AspectRatio(
              aspectRatio: 1.5,
              child: CustomPaint(painter: _ElectrodePainter()),
            ),
          ),
          const Text(
            'RA: upper right chest (green) • LA: upper left chest (red)\nRL: lower right torso (yellow, reference)',
            style: TextStyle(height: 1.6),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            const Text(
              'This kit: RA green, LA red, RL yellow. Match the RA / LA / RL labels on your module and cable; other kits may use different colors. This is one RA–LA channel with an RL reference, not a 12-lead ECG. The reference electrode is not a third measured channel.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Use fresh adhesive pads on clean, dry, intact skin. Sit comfortably, relax your arms, stay still, and secure the wires so they do not pull on the pads. Keep wires short and away from chargers and mains cables.',
            ),
          ],
        ],
      ),
    ),
  );
}

class _ElectrodePainter extends CustomPainter {
  const _ElectrodePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 240);
    final body = Path()
      ..moveTo(155, 57)
      ..lineTo(135, 65)
      ..quadraticBezierTo(112, 67, 105, 95)
      ..lineTo(92, 150)
      ..lineTo(111, 156)
      ..lineTo(128, 110)
      ..lineTo(135, 210)
      ..lineTo(225, 210)
      ..lineTo(232, 110)
      ..lineTo(249, 156)
      ..lineTo(268, 150)
      ..lineTo(255, 95)
      ..quadraticBezierTo(248, 67, 225, 65)
      ..lineTo(205, 57)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF263448));
    canvas.drawCircle(
      const Offset(180, 32),
      22,
      Paint()..color = const Color(0xFF263448),
    );
    void label(String name, String side, Offset dot, Offset text, Color color) {
      canvas.drawLine(
        dot,
        Offset(text.dx + (text.dx < 100 ? 55 : -5), text.dy + 9),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(dot, 9, Paint()..color = color);
      canvas.drawCircle(dot, 4, Paint()..color = Colors.white);
      final tp = TextPainter(
        text: TextSpan(
          text: '$name\n$side',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);
      tp.paint(canvas, text);
    }

    label(
      'RA · green',
      'Your right',
      const Offset(145, 87),
      const Offset(14, 70),
      const Color(0xFF00FF88),
    );
    label(
      'LA · red',
      'Your left',
      const Offset(215, 87),
      const Offset(278, 70),
      const Color(0xFFEF4444),
    );
    label(
      'RL · yellow',
      'Reference',
      const Offset(148, 174),
      const Offset(14, 168),
      const Color(0xFFFBBF24),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ElectrodePainter oldDelegate) => false;
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & electrode placement')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ElectrodeGuide(),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Body-connected electronics: use battery power. Keep the phone and board disconnected from mains-powered chargers and computers while electrodes are attached. Ordinary USB is not medical electrical isolation.',
                style: TextStyle(color: Colors.amber, height: 1.5),
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Signal checks\n\nA lead-connected flag does not prove a clean signal. Strong 50 Hz interference, movement, loose pads or ADC saturation can generate false beat detections. The signal percentage is an experimental electrical-noise estimate, not clinical confidence.\n\nRecorded signals: drag to pan, pinch to zoom in time, and use the amplitude buttons. Tap two points for time/voltage calipers. Values use nominal 250 Hz and an assumed analog gain; they are not calibrated clinical measurements.\n\nR–R variation requires verified beats. Short or noisy segments cannot support reliable HRV, QT/QTc, ST analysis or rhythm diagnosis.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(experimentalNotice, style: TextStyle(height: 1.5)),
            ),
          ),
          const SelectableText(
            'HRV reference: ESC/NASPE Task Force, Heart rate variability, 1996. Standard short-term recordings use 5 minutes under stable conditions, with artifact review.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About FlutBeat')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/branding/flutbeat-icon.png',
                width: 72,
                height: 72,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('FlutBeat', style: Theme.of(context).textTheme.headlineMedium),
          FutureBuilder<PackageInfo>(
            future: _info,
            builder: (context, snapshot) => Text(
              snapshot.hasData
                  ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})\n${snapshot.data!.packageName}'
                  : 'Experimental ECG explorer',
            ),
          ),
          const SizedBox(height: 24),
          const Text(experimentalNotice, style: TextStyle(height: 1.6)),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Open-source licenses'),
            subtitle: const Text(
              'Flutter, dependencies and bundled native USB notices',
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'FlutBeat',
              applicationLegalese: 'Original app artwork and electrode diagram are included with FlutBeat.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Electrode placement & help'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const HelpScreen())),
          ),
        ],
      ),
    ),
  );
}

class OfflineSetup extends StatelessWidget {
  const OfflineSetup({
    super.key,
    required this.connecting,
    required this.onConnect,
    this.error,
  });
  final bool connecting;
  final VoidCallback onConnect;
  final String? error;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final message = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.usb_off_outlined,
            color: Color(0xFF38BDF8),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            connecting
                ? 'Looking for a USB ECG device…'
                : 'No ECG device connected',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect your board with a USB OTG cable and allow USB access. Checking for a connection every 5 seconds. If access was denied, tap Connect to try again.',
            style: TextStyle(height: 1.5),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: connecting ? null : onConnect,
                icon: const Icon(Icons.refresh),
                label: const Text('Connect'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
                ),
                icon: const Icon(Icons.help_outline),
                label: const Text('Help'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
                child: const Text('About / licenses'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            experimentalNotice,
            style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
          ),
        ],
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: constraints.maxWidth >= 700
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 16),
                  const Expanded(child: ElectrodeGuide(compact: true)),
                ],
              )
            : Column(
                children: [
                  message,
                  const SizedBox(height: 12),
                  const ElectrodeGuide(compact: true),
                ],
              ),
      );
    },
  );
}
