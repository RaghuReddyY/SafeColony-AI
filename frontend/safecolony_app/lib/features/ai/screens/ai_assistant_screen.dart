import 'package:flutter/material.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/ai_message.dart';
import '../services/ai_assistant_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AIAssistantService();

  final List<AIMessage> _messages = [];
  bool _sending = false;

  String get _role => ref.read(authProvider).user?.role ?? 'USER';

  List<String> get _suggestions {
    switch (_role) {
      case 'ORGANIZATION_ADMIN':
        return const [
          'Give me a summary of my community',
          'How should I track maintenance payments?',
          'What should I check as an admin today?',
        ];
      case 'SECURITY_GUARD':
      case 'SECURITY_MANAGER':
        return const [
          'What should I verify before allowing a visitor?',
          'How should I handle an arrived delivery?',
          'Show me the important security checks for today',
        ];
      case 'RESIDENT':
        return const [
          'How do I pay my maintenance?',
          'How do I create a visitor request?',
          'How does Vacation Mode work?',
        ];
      default:
        return const [
          'What can SafeColony AI help me with?',
          'Explain the SafeColony workflow',
        ];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();

    setState(() {
      _messages.add(AIMessage(role: 'user', content: text));
      _sending = true;
    });

    _scrollToBottom();

    try {
      final reply = await _service.chat(_messages);
      if (!mounted) return;

      setState(() {
        _messages.add(AIMessage(role: 'assistant', content: reply));
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();
      setState(() {
        _messages.add(
          AIMessage(
            role: 'assistant',
            content: message.contains('Gemini API is not configured')
                ? 'Gemini is not configured on the SafeColony server yet. Add GEMINI_API_KEY to backend/.env and restart the backend.'
                : 'I could not reach the AI service right now. Please try again.',
          ),
        );
        _sending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xffEEF2FF),
              child: Icon(
                Icons.auto_awesome,
                color: Color(0xff4F46E5),
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text('SafeColony AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              children: [
                _welcomeCard(name),
                if (_messages.isEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Try asking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._suggestions.map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _suggestion(text),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ..._messages.map(_messageBubble),
                if (_sending) _typingBubble(),
              ],
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _welcomeCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4F46E5), Color(0xff2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: .20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Hi $name 👋\nAsk me about SafeColony, your tasks, payments, visitors, deliveries or security.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestion(String text) {
    return InkWell(
      onTap: () => _send(text),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xff4F46E5), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(AIMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff4F46E5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xff1E293B),
            height: 1.45,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('SafeColony AI is thinking...'),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask SafeColony AI...',
                  filled: true,
                  fillColor: const Color(0xffF5F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _sending ? null : () => _send(),
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
