import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/guard_provider.dart';
import 'guard_scan_result_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleToken(String token) async {
    if (_handled || token.trim().isEmpty) return;
    _handled = true;
    await _scannerController.stop();
    await ref.read(guardProvider.notifier).validateQR(token.trim());
    if (!mounted) return;
    final state = ref.read(guardProvider);
    if (state.error != null) {
      _handled = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
      await _scannerController.start();
      return;
    }
    if (state.visitor != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GuardScanResultScreen(visitor: state.visitor!)),
      ).then((_) {
        if (mounted) {
          ref.read(guardProvider.notifier).clear();
          _handled = false;
          _scannerController.start();
        }
      });
    }
  }

  Future<void> _manualValidate() async {
    final token = _manualController.text.trim();
    if (token.isEmpty) return;
    await _handleToken(token);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Planned Visitor QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'QR is for resident-created planned visitors. Walk-in visitors do not need QR after resident approval.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              height: 320,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final token = capture.barcodes.firstOrNull?.rawValue;
                  if (token != null) _handleToken(token);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR ENTER TOKEN')), Expanded(child: Divider())]),
            const SizedBox(height: 14),
            TextField(
              controller: _manualController,
              decoration: const InputDecoration(
                labelText: 'QR Token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isLoading ? null : _manualValidate,
                child: state.isLoading ? const CircularProgressIndicator() : const Text('Validate Token'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
