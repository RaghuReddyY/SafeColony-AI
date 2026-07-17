import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/guard_scan_result.dart';
import '../services/guard_service.dart';
import 'qr_scanner_screen.dart';

class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  final GuardService _service = GuardService();

  final TextEditingController _controller =
      TextEditingController();

  GuardScanResult? visitor;

  bool loading = false;

  String error = "";

  Future<void> validateVisitor() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        error = "Please enter QR Token";
      });
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final response = await _service.validate(
        _controller.text.trim(),
      );

      setState(() {
        visitor = response;
      });
    } on DioException catch (e) {
      setState(() {
        visitor = null;
        error =
            e.response?.data["detail"] ??
            "Unable to validate visitor";
      });
    } catch (_) {
      setState(() {
        visitor = null;
        error = "Unexpected error occurred";
      });
    }

    setState(() {
      loading = false;
    });
  }

Future<void> checkInVisitor() async {
  if (visitor == null) return;

  setState(() {
    loading = true;
    error = "";
  });

  try {
    final response = await _service.checkIn(
      _controller.text.trim(),
    );

    setState(() {
      visitor = response;
    });
  } on DioException catch (e) {
    setState(() {
      error =
          e.response?.data["detail"] ??
          "Unable to check in";
    });
  } catch (_) {
    setState(() {
      error = "Unexpected error occurred";
    });
  }

  setState(() {
    loading = false;
  });
}

  Future<void> checkoutVisitor() async {
    if (visitor == null) return;

    setState(() {
      loading = true;
    });

    try {
      final response = await _service.checkOut(
        _controller.text.trim(),
      );

      setState(() {
        visitor = response;
      });
    } on DioException catch (e) {
      setState(() {
        error =
            e.response?.data["detail"] ??
            "Unable to checkout";
      });
    } catch (_) {
      setState(() {
        error = "Unexpected error occurred";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Guard Console",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "QR Token",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

 Row(
  children: [

    Expanded(
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "QR Token",
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    ),

    const SizedBox(width: 10),

    IconButton.filled(

      icon: const Icon(
        Icons.qr_code_scanner,
      ),

      onPressed: () async {

        final token =
            await Navigator.push<String>(

          context,

          MaterialPageRoute(

            builder: (_) =>
                const QRScannerScreen(),
          ),
        );

        if (token != null) {

          _controller.text = token;

          validateVisitor();
        }
      },
    ),
  ],
),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    loading
                        ? null
                        : validateVisitor,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.qr_code_scanner,
                      ),
                label: const Text(
                  "Validate Visitor",
                ),
              ),
            ),

            if (error.isNotEmpty) ...[
              const SizedBox(height: 20),

              Card(
                color: Colors.red.shade50,

                child: Padding(
                  padding:
                      const EdgeInsets.all(14),

                  child: Row(
                    children: [

                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          error,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (visitor != null) ...[

              const SizedBox(height: 30),

              const Text(
                "Visitor Information",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 15),

              Card(
                elevation: 2,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Row(
                        children: [

                          const CircleAvatar(
                            radius: 28,
                            child: Icon(
                              Icons.person,
                            ),
                          ),

                          const SizedBox(
                              width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(
                                  visitor!
                                      .visitorName,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 22,
                                  ),
                                ),

                                Text(
                                  visitor!
                                      .phone,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _statusChip(
                              visitor!.status),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _infoRow(
                        Icons.badge,
                        "Visitor Type",
                        visitor!
                            .visitorType,
                      ),

                      if (visitor!
                              .purpose !=
                          null)
                        _infoRow(
                          Icons.assignment,
                          "Purpose",
                          visitor!
                              .purpose!,
                        ),

                      if (visitor!
                              .vehicleNumber !=  null)
                        _infoRow(
                          Icons
                              .directions_car,
                          "Vehicle",
                          visitor!
                              .vehicleNumber!,
                        ),

                      _infoRow(
                        Icons.home,
                        "Resident ID",
                        visitor!
                            .residentId
                            .toString(),
                      ),

                      const SizedBox(height: 25),

   SizedBox(
  width: double.infinity,
  child: Builder(
    builder: (context) {
      switch (visitor!.status) {
        case "APPROVED":
          return FilledButton.icon(
            onPressed: loading ? null : checkInVisitor,
            icon: const Icon(Icons.login),
            label: const Text("Check In"),
          );

        case "CHECKED_IN":
          return FilledButton.icon(
            onPressed: loading ? null : checkoutVisitor,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Check Out"),
          );

        case "CHECKED_OUT":
          return FilledButton.icon(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text("Visit Completed"),
          );

        case "REJECTED":
          return FilledButton.icon(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            icon: const Icon(Icons.cancel),
            label: const Text("Visitor Rejected"),
          );

        default:
          return FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_bottom),
            label: Text(visitor!.status),
          );
      }
    },
  ),
),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
      Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "APPROVED":
        color = Colors.blue;
        break;

      case "CHECKED_IN":
        color = Colors.green;
        break;

      case "CHECKED_OUT":
        color = Colors.grey;
        break;

      case "REJECTED":
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.indigo,
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}