import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resident/services/family_invite_service.dart';

class FamilyInviteCard extends StatefulWidget {
  const FamilyInviteCard({super.key});

  @override
  State<FamilyInviteCard> createState() => _FamilyInviteCardState();
}

class _FamilyInviteCardState extends State<FamilyInviteCard> {
  final _service = FamilyInviteService();
  bool _loading = false;
  String? _code;
  String? _unit;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getInvite();
      if (!mounted) return;
      setState(() {
        _code = data['code']?.toString();
        _unit = data['unit_number']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xffEEF2FF),
              child: Icon(Icons.family_restroom, color: Color(0xff4F46E5)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite family members', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Let your family join the app under the same unit without creating another unit.'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (_code != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_unit == null ? '' : 'Unit $_unit', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(_code!, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      IconButton(onPressed: _copyCode, icon: const Icon(Icons.copy_rounded)),
                    ],
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.key_rounded),
                label: Text(_loading ? 'Loading...' : 'Get Code'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FamilyInviteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family join code copied.')));
  }
}
