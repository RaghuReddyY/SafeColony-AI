import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() =>
      _QRScannerScreenState();
}

class _QRScannerScreenState
    extends State<QRScannerScreen> {

  bool scanned = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Scan Visitor QR"),
      ),

      body: MobileScanner(

        onDetect: (capture) {

          if (scanned) return;

          final barcode =
              capture.barcodes.first;

          final value = barcode.rawValue;

          if (value == null) return;

          scanned = true;

          Navigator.pop(
            context,
            value,
          );
        },
      ),
    );
  }
}