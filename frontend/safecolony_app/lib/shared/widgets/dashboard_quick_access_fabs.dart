import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/ai/screens/ai_assistant_screen.dart';
import '../../features/chat/screens/community_chat_screen.dart';
import '../../features/chat/services/chat_service.dart';

/// Persistent dashboard shortcuts for AI and Community Chat.
/// On phones the shortcuts stay compact so they do not cover dashboard content.
class DashboardQuickAccessFabs extends StatefulWidget {
  const DashboardQuickAccessFabs({super.key});

  @override
  State<DashboardQuickAccessFabs> createState() => _DashboardQuickAccessFabsState();
}

class _DashboardQuickAccessFabsState extends State<DashboardQuickAccessFabs> {
  final ChatService _chatService = ChatService();
  Timer? _timer;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _loadUnread());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnread() async {
    try {
      final conversations = await _chatService.conversations();
      if (!mounted) return;
      setState(() {
        _unreadChatCount = conversations.fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        );
      });
    } catch (_) {}
  }

  Future<void> _openChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityChatScreen()),
    );
    if (mounted) _loadUnread();
  }

  void _openAi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              heroTag: 'safe_colony_chat_fab',
              mini: true,
              tooltip: 'Community Chat',
              onPressed: _openChat,
              backgroundColor: const Color(0xff0F766E),
              foregroundColor: Colors.white,
              child: const Icon(Icons.forum_rounded),
            ),
            if (_unreadChatCount > 0)
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (mobile)
          FloatingActionButton(
            heroTag: 'safe_colony_ai_fab',
            mini: true,
            tooltip: 'AI Assistant',
            onPressed: _openAi,
            backgroundColor: const Color(0xff4F46E5),
            foregroundColor: Colors.white,
            child: const Icon(Icons.auto_awesome_rounded),
          )
        else
          FloatingActionButton.extended(
            heroTag: 'safe_colony_ai_fab',
            onPressed: _openAi,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('AI Assistant'),
            backgroundColor: const Color(0xff4F46E5),
            foregroundColor: Colors.white,
          ),
      ],
    );
  }
}
