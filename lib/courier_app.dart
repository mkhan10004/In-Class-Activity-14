import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'courier_state.dart';
import 'fcm_service.dart';

const _ink = Color(0xFF102B31);
const _teal = Color(0xFF00685C);
const _muted = Color(0xFF455D60);
const _canvas = Color(0xFFF0F5F3);

class CourierApp extends StatelessWidget {
  const CourierApp({super.key, this.service, this.setupMessage});

  final FCMService? service;
  final String? setupMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Courier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _teal),
        scaffoldBackgroundColor: _canvas,
        useMaterial3: true,
      ),
      home: _CourierScreen(service: service, setupMessage: setupMessage),
    );
  }
}

class _CourierScreen extends StatefulWidget {
  const _CourierScreen({this.service, this.setupMessage});

  final FCMService? service;
  final String? setupMessage;

  @override
  State<_CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<_CourierScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service?.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.service?.refreshDevice());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const _Header(),
                const SizedBox(height: 16),
                if (service == null) ...[
                  const _Announcement(state: CourierState()),
                  const SizedBox(height: 12),
                  _Panel(
                    child: _Notice(
                      icon: Icons.settings_outlined,
                      text: widget.setupMessage ?? 'Firebase setup required.',
                    ),
                  ),
                ] else
                  ListenableBuilder(
                    listenable: service,
                    builder: (context, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Announcement(state: service.state),
                        const SizedBox(height: 12),
                        _Receipt(state: service.state),
                        const SizedBox(height: 12),
                        _DevicePanel(service: service),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.cloud_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cloud Courier',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: _ink),
              ),
              const Text(
                'CAMPUS ANNOUNCEMENTS',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Announcement extends StatelessWidget {
  const _Announcement({required this.state});

  final CourierState state;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            state.asset.path,
            height: 126,
            fit: BoxFit.cover,
            semanticLabel: state.asset == CourierAsset.promo
                ? 'Campus event illustration'
                : 'Campus bulletin illustration',
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE ASSET  •  ${state.asset.payloadValue}',
                  style: const TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: _ink, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(state.body, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});

  final CourierState state;

  @override
  Widget build(BuildContext context) {
    final diagnostic = state.diagnostic;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Delivery evidence',
            trailing: '${state.count} this launch',
          ),
          const SizedBox(height: 9),
          _Detail(
            label: 'Last handler',
            value: state.path?.label ?? 'Waiting for a message',
          ),
          const SizedBox(height: 5),
          _Detail(label: 'Message ID', value: state.messageId ?? '—'),
          if (diagnostic != null) ...[
            const SizedBox(height: 10),
            _Notice(icon: Icons.warning_amber_rounded, text: diagnostic),
          ],
        ],
      ),
    );
  }
}

class _DevicePanel extends StatelessWidget {
  const _DevicePanel({required this.service});

  final FCMService service;

  Future<void> _copyToken(BuildContext context, String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Device token copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = service.token;
    final permission = service.permission;
    final deviceError = service.deviceError;
    final listenerError = service.listenerError;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.phone_android, title: 'Test device'),
          const SizedBox(height: 9),
          _Detail(
            label: 'Notifications',
            value: switch (permission) {
              AuthorizationStatus.authorized => 'Authorized',
              AuthorizationStatus.denied => 'Denied or not yet granted',
              AuthorizationStatus.deniedPermanently => 'Denied or not yet granted',
              AuthorizationStatus.notDetermined => 'Not requested',
              AuthorizationStatus.provisional => 'Provisional',
              null => 'Checking…',
            },
          ),
          const SizedBox(height: 5),
          _Detail(
            label: 'FCM token',
            value: token != null
                ? 'Available'
                : service.checkingDevice
                ? 'Checking…'
                : 'Unavailable',
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (permission != AuthorizationStatus.authorized)
                FilledButton.tonal(
                  onPressed: service.checkingDevice
                      ? null
                      : () => service.refreshDevice(requestPermission: true),
                  child: const Text('Allow notifications'),
                ),
              OutlinedButton.icon(
                onPressed: token == null
                    ? null
                    : () => _copyToken(context, token),
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy token'),
              ),
              TextButton(
                onPressed: service.checkingDevice
                    ? null
                    : () => service.refreshDevice(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          if (deviceError != null)
            _Notice(icon: Icons.info_outline, text: deviceError),
          if (listenerError != null)
            _Notice(icon: Icons.info_outline, text: listenerError),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(15)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDCE8E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        if (trailing case final text?)
          Text(
            text,
            style: const TextStyle(color: _teal, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF754B0E)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF62400E))),
          ),
        ],
      ),
    );
  }
}
