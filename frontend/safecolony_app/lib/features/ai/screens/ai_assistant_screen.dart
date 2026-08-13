import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/community_chat_screen.dart';
import '../models/ai_message.dart';
import '../models/ai_overview.dart';
import '../services/ai_assistant_service.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _service = AIAssistantService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  bool _sending = false;
  bool _loadingOverview = true;
  AIOverview? _overview;
  String? _overviewError;

  String get _role => ref.read(authProvider).user?.role ?? 'USER';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadOverview();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loadingOverview = true;
      _overviewError = null;
    });
    try {
      final overview = await _service.overview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loadingOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOverview = false;
        _overviewError = e.toString();
      });
    }
  }

  List<String> get _suggestions {
    switch (_role) {
      case 'ORGANIZATION_ADMIN':
      case 'PROPERTY_MANAGER':
        return const [
          'Give me a detailed community security summary',
          'Summarize open incidents and complaints and tell me what needs attention',
          'Give me today\'s community operations report',
          'What should I prioritize today as an administrator?',
        ];
      case 'SECURITY_GUARD':
      case 'SECURITY_MANAGER':
        return const [
          'Give me the current gate and security workload',
          'What visitor activity needs attention right now?',
          'Summarize unresolved security alerts and incidents',
          'What should I check before allowing a visitor entry?',
        ];
      case 'RESIDENT':
        return const [
          'Give me a summary of my dashboard and pending actions',
          'What is my maintenance status and balance?',
          'What visitors and deliveries need my attention?',
          'Explain my current Vacation Mode and notifications',
        ];
      default:
        return const [
          'Give me the current SafeColony operational summary',
          'What can SafeColony AI help me with?',
        ];
    }
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
      setState(() {
        _messages.add(AIMessage(
          role: 'assistant',
          content: e.toString().contains('Gemini API is not configured')
              ? 'Gemini is not configured on the SafeColony server. Add GEMINI_API_KEY to backend/.env and restart the backend.'
              : 'I could not reach the AI service right now. Please try again.',
        ));
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
              child: Icon(Icons.auto_awesome, color: Color(0xff4F46E5), size: 20),
            ),
            SizedBox(width: 10),
            Text('SafeColony AI'),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.insights_rounded), text: 'AI Insights'),
            Tab(icon: Icon(Icons.smart_toy_rounded), text: 'AI Chat'),
            Tab(icon: Icon(Icons.forum_rounded), text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _insightsTab(),
          _aiChatTab(name),
          const CommunityChatScreen(),
        ],
      ),
    );
  }

  Widget _insightsTab() {
    if (_loadingOverview) return const Center(child: CircularProgressIndicator());
    if (_overviewError != null && _overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 12),
              const Text('Unable to load AI insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_overviewError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _loadOverview, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final overview = _overview!;
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _overviewHero(overview),
          const SizedBox(height: 16),
          ...overview.insights.map(_insightCard),
          const SizedBox(height: 10),
          const Text('Future AI capabilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...overview.futureFeatures.map(_futureCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _overviewHero(AIOverview overview) {
    final m = overview.metrics;
    final alerts = (m['active_security_alerts'] as num?)?.toInt() ?? 0;
    final incidents = (m['open_incidents'] as num?)?.toInt() ?? 0;
    final unread = (m['unread_notifications'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff4F46E5), Color(0xff2563EB)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live AI Operations Center', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Role-aware insights are calculated from the same live community data used by the dashboard.',
            style: TextStyle(color: Colors.white.withValues(alpha: .9), height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('Alerts', alerts, Icons.warning_amber_rounded),
              _metricChip('Incidents', incidents, Icons.report_problem_outlined),
              _metricChip('Unread', unread, Icons.notifications_none),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Text('$label: $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _insightCard(AIInsight insight) {
    final critical = insight.priority == 'HIGH';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: critical ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: critical ? Colors.red.shade50 : Colors.indigo.shade50,
          child: Icon(_iconForCategory(insight.category), color: critical ? Colors.red : Colors.indigo),
        ),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(insight.summary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          ...insight.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xff64748B)),
                  const SizedBox(width: 9),
                  Expanded(child: Text(detail, style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
          ),
          if (insight.action != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xffEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: Text('Next: ${insight.action}', style: const TextStyle(color: Color(0xff3730A3), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          if (insight.key == 'reports' || insight.key == 'report_generator') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _generateReport(),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Generate live report'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    try {
      final report = await _service.report(
        _role == 'RESIDENT' ? 'RESIDENT' :
        (_role == 'SECURITY_GUARD' || _role == 'SECURITY_MANAGER') ? 'SECURITY' : 'COMMUNITY',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('AI Report'),
          content: SingleChildScrollView(child: SelectableText(report)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to generate report: $e')),
      );
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'SECURITY': return Icons.security_rounded;
      case 'INCIDENT': return Icons.report_problem_rounded;
      case 'VISITOR': return Icons.people_alt_rounded;
      case 'PARKING': return Icons.local_parking_rounded;
      case 'NOTIFICATIONS': return Icons.notifications_active_rounded;
      case 'COMMUNITY': return Icons.apartment_rounded;
      case 'DIGEST': return Icons.today_rounded;
      case 'REPORT': return Icons.assessment_rounded;
      case 'RESIDENT': return Icons.home_rounded;
      case 'GUARD': return Icons.shield_rounded;
      case 'COPILOT': return Icons.auto_awesome_rounded;
      default: return Icons.insights_rounded;
    }
  }

  Widget _futureCard(AIFutureFeature feature) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
        title: Text(feature.title),
        subtitle: Text(feature.description),
        trailing: const Text('FUTURE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _aiChatTab(String name) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            children: [
              _welcomeCard(name),
              if (_messages.isEmpty) ...[
                const SizedBox(height: 20),
                const Text('Ask about your live dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _welcomeCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff4F46E5), Color(0xff2563EB)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Hi $name 👋\nI can reason over your live SafeColony dashboard, incidents, visitors, security, maintenance and community operations.',
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffE2E8F0))),
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
          style: TextStyle(color: isUser ? Colors.white : const Color(0xff1E293B), height: 1.45, fontSize: 15),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, -3))]),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(onPressed: _sending ? null : () => _send(), icon: const Icon(Icons.send_rounded)),
          ],
        ),
      ),
    );
  }
}
