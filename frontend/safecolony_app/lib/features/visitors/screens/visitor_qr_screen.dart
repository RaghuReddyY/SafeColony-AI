
// NOTE:
// This is a starter production-ready Visitor QR screen.
// Replace your existing visitor_qr_screen.dart with this file and
// adapt imports if your project structure differs.

import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/services/platform_file_service.dart';
import '../models/visitor.dart';

class VisitorQRScreen extends StatefulWidget {
  final Visitor visitor;

  const VisitorQRScreen({
    super.key,
    required this.visitor,
  });

  @override
  State<VisitorQRScreen> createState() => _VisitorQRScreenState();
}

class _VisitorQRScreenState extends State<VisitorQRScreen> {
  bool _busy = false;

  Future<void> _share() async {
    if (widget.visitor.qrCode == null) return;
    try {
      setState(() => _busy = true);
      final bytes = await QRService.downloadQR(widget.visitor.qrCode!);
      await PlatformFileService.shareFile(
        bytes,
        "visitor_${widget.visitor.id}.png",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR shared successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Share failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (widget.visitor.qrCode == null) return;
    try {
      setState(() => _busy = true);
      final bytes = await QRService.downloadQR(widget.visitor.qrCode!);
      await PlatformFileService.saveFile(
        bytes,
        "visitor_${widget.visitor.id}.png",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR downloaded")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final qr = width > 700 ? 320.0 : width > 450 ? 260.0 : 220.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Visitor QR"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.verified, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(widget.visitor.visitorName,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Chip(label: Text(widget.visitor.status)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: qr,
                        height: qr,
                        child: widget.visitor.qrCode == null
                            ? const Center(child: Text("QR Not Available"))
                            : Image.network(
                                "${ApiConstants.baseUrl}/${widget.visitor.qrCode!}",
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 24),
                      if (_busy) const CircularProgressIndicator(),
                      if (!_busy) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _share,
                            icon: const Icon(Icons.share),
                            label: const Text("Share QR"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _download,
                            icon: const Icon(Icons.download),
                            label: const Text("Download QR"),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
