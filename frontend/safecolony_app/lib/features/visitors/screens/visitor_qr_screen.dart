import 'package:flutter/material.dart';

import '../models/visitor.dart';

class VisitorQRScreen extends StatelessWidget {
  final Visitor visitor;

  const VisitorQRScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor QR"),
      ),

      body: Center(

        child: Padding(
          padding: const EdgeInsets.all(30),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.verified,
                color: Colors.green,
                size: 70,
              ),

              const SizedBox(height: 15),

              Text(
                visitor.visitorName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                visitor.status,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                ),

                child: visitor.qrCode == null
                    ? const Center(
                        child: Text(
                          "QR Not Available",
                        ),
                      )
                    : Image.network(
                        "http://127.0.0.1:8000/${visitor.qrCode!}",
                        fit: BoxFit.contain,
                      ),
              ),

              const SizedBox(height: 35),

              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: const Text("Share QR"),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text("Download"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}