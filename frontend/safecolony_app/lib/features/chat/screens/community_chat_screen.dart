import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState
    extends ConsumerState<CommunityChatScreen> {
  final _service = ChatService();
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _search = TextEditingController();

  List<ChatConversation> _conversations = [];
  List<ChatUser> _users = [];
  List<ChatMessage> _messages = [];

  ChatConversation? _selected;

  Timer? _poller;

  bool _loading = true;
  bool _sending = false;

  PlatformFile? _attachment;

  String? _error;

  @override
  void initState() {
    super.initState();

    _load();

    _poller = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (_selected != null && mounted) {
          _loadMessages(showLoading: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _composer.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await _service.conversations();

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openCommunity() async {
    try {
      final conversation = await _service.community();
      await _select(conversation);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _service.users(
        search: _search.text,
      );

      if (!mounted) return;

      setState(() {
        _users = users;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _startDirect(ChatUser user) async {
    try {
      final conversation = await _service.startDirect(user.id);

      if (!mounted) return;

      Navigator.pop(context);

      await _select(conversation);
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _select(ChatConversation conversation) async {
    setState(() {
      _selected = conversation;
      _messages = [];
    });

    await _loadMessages();
  }

  Future<void> _loadMessages({
    bool showLoading = true,
  }) async {
    final selected = _selected;

    if (selected == null) return;

    try {
      final messages = await _service.messages(selected.id);

      await _service.markRead(selected.id);

      if (!mounted) return;

      setState(() {
        _messages = messages;
      });

      if (showLoading) {
        _scrollToBottom();
      }
    } catch (e) {
      if (showLoading) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _send() async {
    final selected = _selected;
    final text = _composer.text.trim();

    if (selected == null ||
        _sending ||
        (text.isEmpty && _attachment == null)) {
      return;
    }

    final attachment = _attachment;

    _composer.clear();

    setState(() {
      _sending = true;
    });

    try {
      final message = attachment == null
          ? await _service.send(
              selected.id,
              text,
            )
          : await _service.sendAttachment(
              selected.id,
              text,
              attachment,
            );

      if (!mounted) return;

      setState(() {
        _messages.add(message);
        _attachment = null;
        _sending = false;
      });

      _scrollToBottom();

      await _load();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showError(e.toString());
    }
  }

 Future<void> _pickAttachment() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'pdf',
    ],
  );

  if (files.isEmpty) return;

  final file = files.single;

  try {
    final bytes = await file.readAsBytes();

    if (bytes.length > 10 * 1024 * 1024) {
      _showError('Attachment must be 10 MB or smaller.');
      return;
    }

    if (!mounted) return;

    // Keep the actual PlatformFile returned by file_picker.
    // Do NOT create PlatformFile manually.
    setState(() {
      _attachment = file;
    });
  } catch (e) {
    _showError('Unable to read the selected attachment.');
  }
}

  Future<void> _editMessage(ChatMessage message) async {
    final controller = TextEditingController(
      text: message.content,
    );

    try {
      final updatedText = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 4000,
            decoration: const InputDecoration(
              hintText: 'Update your message...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isNotEmpty) {
                  Navigator.pop(
                    dialogContext,
                    text,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (updatedText == null ||
          updatedText.trim() == message.content.trim()) {
        return;
      }

      final selected = _selected;

      if (selected == null) return;

      final updated = await _service.edit(
        selected.id,
        message.id,
        updatedText.trim(),
      );

      if (!mounted) return;

      setState(() {
        final index = _messages.indexWhere(
          (m) => m.id == message.id,
        );

        if (index >= 0) {
          _messages[index] = updated;
        }
      });

      await _load();
    } catch (e) {
      _showError(e.toString());
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final selected = _selected;

    if (selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'The message will be replaced with '
          '“This message was deleted” for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleted = await _service.delete(
        selected.id,
        message.id,
      );

      if (!mounted) return;

      setState(() {
        final index = _messages.indexWhere(
          (m) => m.id == message.id,
        );

        if (index >= 0) {
          _messages[index] = deleted;
        }
      });

      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;

      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 200,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }

  String _conversationName(
    ChatConversation conversation,
  ) {
    if (conversation.type == 'COMMUNITY') {
      return 'Community Chat';
    }

    final me = ref.read(authProvider).user?.id;

    ChatUser? other;

    for (final participant in conversation.participants) {
      if (participant.id != me) {
        other = participant;
        break;
      }
    }

    return other?.fullName ??
        conversation.name ??
        'Direct Chat';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: Text(
          _selected == null
              ? 'Community Chat'
              : _conversationName(_selected!),
        ),
        actions: [
          IconButton(
            tooltip:
                'Find residents, guards and admins',
            onPressed: _showPeople,
            icon: const Icon(
              Icons.person_search_rounded,
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _selected == null
          ? _conversationList()
          : _chatView(),
    );
  }

  Widget _conversationList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null &&
        _conversations.isEmpty) {
      return Center(
        child: Text(
          'Unable to load chat.\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.groups_rounded),
              ),
              title: const Text(
                'Community Chat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Chat with residents, guards and administrators',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: _openCommunity,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your conversations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_conversations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No direct conversations yet.',
                ),
              ),
            ),
          ..._conversations.map(
            (conversation) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    conversation.type == 'COMMUNITY'
                        ? Icons.groups
                        : Icons.person,
                  ),
                ),
                title: Text(
                  _conversationName(conversation),
                ),
                subtitle: Text(
                  conversation.lastMessage?.content ??
                      'Start a conversation',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                trailing:
                    conversation.unreadCount > 0
                        ? CircleAvatar(
                            radius: 13,
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right,
                          ),
                onTap: () => _select(
                  conversation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatView() {
    final me = ref.watch(authProvider).user?.id;

    return Column(
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              setState(() {
                _selected = null;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Text('All conversations'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMessages,
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                14,
                16,
                14,
                16,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                final mine =
                    message.senderUserId == me;

                final canModify =
                    mine && !message.isDeleted;

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 650,
                    ),
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? const Color(0xff4F46E5)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      border: mine
                          ? null
                          : Border.all(
                              color: const Color(
                                0xffE2E8F0,
                              ),
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  if (!mine)
                                    Text(
                                      '${message.senderName} • '
                                      '${message.senderRole.replaceAll('_', ' ')}',
                                      style:
                                          const TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: Color(
                                          0xff64748B,
                                        ),
                                      ),
                                    ),
                                  if (!mine)
                                    const SizedBox(
                                      height: 4,
                                    ),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : const Color(
                                              0xff1E293B,
                                            ),
                                      height: 1.4,
                                      fontStyle:
                                          message.isDeleted
                                              ? FontStyle
                                                  .italic
                                              : FontStyle
                                                  .normal,
                                    ),
                                  ),
                                  ...message.attachments
                                      .map(
                                    (attachment) =>
                                        Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                        top: 8,
                                      ),
                                      child: InkWell(
                                        onTap: attachment
                                                .fileUrl
                                                .isEmpty
                                            ? null
                                            : () =>
                                                launchUrl(
                                                  Uri.parse(
                                                    attachment
                                                        .fileUrl,
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            Icon(
                                              attachment
                                                      .contentType
                                                      .startsWith(
                                                    'image/',
                                                  )
                                                  ? Icons
                                                      .image_outlined
                                                  : Icons
                                                      .picture_as_pdf_outlined,
                                              size: 20,
                                              color: mine
                                                  ? Colors
                                                      .white
                                                  : const Color(
                                                      0xff4F46E5,
                                                    ),
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Flexible(
                                              child:
                                                  Text(
                                                attachment
                                                    .fileName,
                                                style:
                                                    TextStyle(
                                                  color: mine
                                                      ? Colors
                                                          .white
                                                      : const Color(
                                                          0xff334155,
                                                        ),
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (message.isEdited &&
                                      !message.isDeleted)
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                        top: 3,
                                      ),
                                      child: Text(
                                        'edited',
                                        style:
                                            TextStyle(
                                          color: mine
                                              ? Colors
                                                  .white70
                                              : const Color(
                                                  0xff94A3B8,
                                                ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (canModify) ...[
                              const SizedBox(width: 6),
                              PopupMenuButton<String>(
                                padding:
                                    EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                iconSize: 18,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editMessage(
                                      message,
                                    );
                                  }

                                  if (value == 'delete') {
                                    _deleteMessage(
                                      message,
                                    );
                                  }
                                },
                                itemBuilder: (_) =>
                                    const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      contentPadding:
                                          EdgeInsets.zero,
                                      dense: true,
                                      leading: Icon(
                                        Icons
                                            .edit_outlined,
                                      ),
                                      title:
                                          Text('Edit'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      contentPadding:
                                          EdgeInsets.zero,
                                      dense: true,
                                      leading: Icon(
                                        Icons
                                            .delete_outline,
                                        color: Colors.red,
                                      ),
                                      title:
                                          Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              10,
            ),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_attachment != null)
                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(
                        Icons.attach_file,
                        size: 18,
                      ),
                      label: Text(
                        _attachment!.name,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      onDeleted: _sending
                          ? null
                          : () {
                              setState(() {
                                _attachment = null;
                              });
                            },
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip:
                          'Attach image or PDF',
                      onPressed: _sending
                          ? null
                          : _pickAttachment,
                      icon: const Icon(
                        Icons.attach_file,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                        decoration:
                            InputDecoration(
                          hintText:
                              'Write a message...',
                          filled: true,
                          fillColor:
                              const Color(
                            0xffF5F7FB,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            borderSide:
                                BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed:
                          _sending ? null : _send,
                      icon: const Icon(
                        Icons.send_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPeople() {
    _search.clear();
    _users = [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom:
                      MediaQuery.of(context)
                              .viewInsets
                              .bottom +
                          16,
                ),
                child: SizedBox(
                  height:
                      MediaQuery.of(context)
                              .size
                              .height *
                          .75,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start a conversation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (_) async {
                          final users =
                              await _service.users(
                            search: _search.text,
                          );

                          if (context.mounted) {
                            setSheetState(
                              () => _users = users,
                            );
                          }
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              'Search residents, guards or admins',
                          prefixIcon:
                              const Icon(
                            Icons.search,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _users.isEmpty
                            ? Center(
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      () async {
                                    final users =
                                        await _service
                                            .users(
                                      search:
                                          _search
                                              .text,
                                    );

                                    if (context
                                        .mounted) {
                                      setSheetState(
                                        () => _users =
                                            users,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.search,
                                  ),
                                  label: const Text(
                                    'Search community',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    _users.length,
                                itemBuilder:
                                    (_, index) {
                                  final user =
                                      _users[index];

                                  return ListTile(
                                    leading:
                                        const CircleAvatar(
                                      child: Icon(
                                        Icons.person,
                                      ),
                                    ),
                                    title: Text(
                                      user.fullName,
                                    ),
                                    subtitle:
                                        Text(
                                      user.role
                                          .replaceAll(
                                        '_',
                                        ' ',
                                      ),
                                    ),
                                    trailing:
                                        const Icon(
                                      Icons
                                          .chat_bubble_outline,
                                    ),
                                    onTap: () =>
                                        _startDirect(
                                      user,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}