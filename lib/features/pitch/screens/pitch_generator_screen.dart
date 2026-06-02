import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/services/user_profile_repository.dart';
import '../../radar/models/scout_lead.dart';
import '../../radar/models/scout_scan_result.dart';
import '../services/mistral_pitch_service.dart';
import '../models/pitch_template.dart';
import '../services/pitch_template_repository.dart';

class PitchGeneratorScreen extends StatefulWidget {
  final ScoutLead? lead;
  final ScoutScanResult? scanResult;

  const PitchGeneratorScreen({
    super.key,
    this.lead,
    this.scanResult,
  });

  @override
  State<PitchGeneratorScreen> createState() => _PitchGeneratorScreenState();
}

class _PitchGeneratorScreenState extends State<PitchGeneratorScreen> {
  final MistralPitchService _pitchService = MistralPitchService();
  final PitchTemplateRepository _templateRepo = PitchTemplateRepository.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late final List<Map<String, dynamic>> _messages;
  final List<Map<String, String>> _conversationHistory = [];
  List<String> _suggestions = const [];
  bool _isBootstrapping = false;
  bool _isReplying = false;
  String? _bootstrapError;
  String? _lastCopiedMessage;
  bool _showHistoryDrawer = false;
  List<Map<String, dynamic>> _pastThreads = [];
  bool _isLoadingThreads = false;
  List<PitchTemplate> _templates = [];
  String? _selectedTemplateCategory;

  String get _threadId => widget.lead?.placeId ?? 'general';

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_handleFocusChange);
    final leadName = widget.lead?.name;
    _messages = [
      {
        'isUser': false,
        'text': leadName == null || leadName.isEmpty
            ? widget.scanResult != null
                ? "Hi! I'm Scout AI. I can rank your best local leads from this scan, write the outreach, and help you close them."
                : "Hi! I'm Scout AI. Give me a lead and I’ll help you analyze it, pitch it, follow up, and price the job."
            : "Hi! I'm Scout AI. I can break down $leadName, tell you how strong the opportunity is, write the outreach, and help you close it.",
      },
    ];
    _restoreConversation();
    if (widget.lead != null) {
      _bootstrapLeadContext();
    } else if (widget.scanResult != null) {
      _suggestions = const [
        'What are my top 3 leads right now?',
        'Which lead should I contact first?',
        'Write a pitch for the best lead',
      ];
    } else {
      _suggestions = const [
        'Analyze this lead for me',
        'Write a short outreach pitch',
        'What should I charge?',
      ];
    }
  }

  Future<void> _restoreConversation() async {
    try {
      final savedHistory = await UserProfileRepository.instance.loadPitchConversation(
        _threadId,
      );
      if (!mounted || savedHistory.isEmpty) {
        return;
      }
      setState(() {
        _conversationHistory
          ..clear()
          ..addAll(savedHistory);
        _messages.addAll(
          savedHistory.map(
            (entry) => {
              'isUser': entry['role'] == 'user',
              'text': entry['content'] ?? '',
            },
          ),
        );
      });
    } catch (_) {
      // Silently fail — conversation will start fresh
    }
  }

  Future<void> _loadPastThreads() async {
    if (_isLoadingThreads) return;
    setState(() {
      _isLoadingThreads = true;
    });
    try {
      final threads = await UserProfileRepository.instance.loadAllPitchThreads();
      if (mounted) {
        setState(() {
          _pastThreads = threads;
          _isLoadingThreads = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingThreads = false;
        });
      }
    }
  }

  void _openThread(String threadId) {
    Navigator.of(context).pop();
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
    });
    _restoreConversationForThread(threadId);
  }

  Future<void> _restoreConversationForThread(String threadId) async {
    try {
      final savedHistory = await UserProfileRepository.instance.loadPitchConversation(
        threadId,
      );
      if (!mounted || savedHistory.isEmpty) {
        return;
      }
      setState(() {
        _conversationHistory
          ..clear()
          ..addAll(savedHistory);
        _messages.addAll(
          savedHistory.map(
            (entry) => {
              'isUser': entry['role'] == 'user',
              'text': entry['content'] ?? '',
            },
          ),
        );
      });
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> _deleteThread(String threadId) async {
    await UserProfileRepository.instance.deletePitchThread(threadId);
    if (mounted) {
      _loadPastThreads();
    }
  }

  Future<void> _showTemplates() async {
    final templates = _templateRepo.getBuiltinTemplates();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pitch Templates',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a template to start your outreach',
                    style: TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TemplateFilterBar(
                    selected: _selectedTemplateCategory,
                    onSelected: (category) {
                      setState(() {
                        _selectedTemplateCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildTemplateList(templates),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateList(List<PitchTemplate> templates) {
    final filtered = _selectedTemplateCategory == null
        ? templates
        : templates
            .where((t) => t.category == _selectedTemplateCategory)
            .toList();

    final scenarioGroups = <String, List<PitchTemplate>>{};
    for (final t in filtered) {
      scenarioGroups.putIfAbsent(t.scenario, () => []).add(t);
    }

    return ListView(
      children: scenarioGroups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  color: Color(0xFF6E6E6E),
                  fontSize: 12,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ...entry.value.map((template) {
              return GestureDetector(
                onTap: () => _useTemplate(template),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForCategory(template.category),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              template.description,
                              style: const TextStyle(
                                color: Color(0xFF7A7A7A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFFB7B7B7),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Email':
        return Icons.email_rounded;
      case 'Social':
        return Icons.share_rounded;
      case 'Phone':
        return Icons.phone_rounded;
      case 'WhatsApp':
        return Icons.chat_rounded;
      case 'Service':
        return Icons.build_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  void _useTemplate(PitchTemplate template) {
    Navigator.of(context).pop();
    final lead = widget.lead;
    String prompt;
    if (lead != null) {
      final context = _templateRepo.buildContextFromLead(
        businessName: lead.name,
        category: lead.selectedCategory,
        location: lead.address,
        gaps: lead.matchedGaps.toList(),
        rating: lead.hasRatings ? lead.rating!.toStringAsFixed(1) : null,
        reviews: lead.hasRatings ? lead.userRatingsTotal.toString() : null,
        photoCount: lead.photoCount.toString(),
      );
      prompt = _templateRepo.fillTemplatePrompt(template, context);
    } else {
      prompt = template.prompt
          .replaceAll('{businessName}', 'this business')
          .replaceAll('{category}', 'their industry')
          .replaceAll('{location}', 'their area')
          .replaceAll('{gaps}', 'their digital presence gaps')
          .replaceAll('{rating}', 'their current rating')
          .replaceAll('{reviews}', 'their review count')
          .replaceAll('{photoCount}', 'their photo count');
    }
    _submitPrompt(prompt);
  }

  Future<void> _showConversationHistory() async {
    await _loadPastThreads();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Past Conversations',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingThreads
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _pastThreads.isEmpty
                            ? const Center(
                                child: Text(
                                  'No past conversations yet.',
                                  style: TextStyle(
                                    color: Color(0xFF7A7A7A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _pastThreads.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final thread = _pastThreads[index];
                                  final lastMsg = thread['lastMessage'] as String? ?? '';
                                  final preview = lastMsg.length > 60
                                      ? '${lastMsg.substring(0, 60)}...'
                                      : lastMsg;
                                  return GestureDetector(
                                    onTap: () => _openThread(thread['id'] as String),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F7F4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.chat_bubble_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  thread['title'] as String,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  preview.isEmpty
                                                      ? '${thread['messageCount']} messages'
                                                      : preview,
                                                  style: const TextStyle(
                                                    color: Color(0xFF7A7A7A),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Color(0xFFC2C2C2),
                                              size: 20,
                                            ),
                                            onPressed: () => _deleteThread(
                                                thread['id'] as String),
                                          ),
                                        ],
                                      ),
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
  }

  @override
  void dispose() {
    _inputFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _systemPrompt {
    final lead = widget.lead;
    if (lead == null) {
      if (widget.scanResult != null) {
        return _pitchService.buildScanSystemPrompt(widget.scanResult!);
      }
      return '''
You are Scout AI, a lead-closing assistant for freelancers using Founders Scout.
- Help the user analyze lead quality, write concise outreach, create follow-ups, and suggest pricing.
- Think like a sales strategist focused on helping the user get clients.
- If the user shares a lead, explain why it is a high, medium, or low opportunity.
- Support rewrites like "make it shorter" or "sound more professional".
- Stay practical, direct, and results-focused.
- Never pretend you can see WhatsApp replies or real conversations.
- NEVER use markdown formatting. Do NOT use asterisks (**), hashtags (###), underscores, or any special formatting characters.
- Respond in plain text only.
''';
    }
    return _pitchService.buildLeadSystemPrompt(lead);
  }

  Future<void> _bootstrapLeadContext() async {
    setState(() {
      _isBootstrapping = true;
      _bootstrapError = null;
    });

    try {
      final suggestions = await _pitchService.generateSuggestions(widget.lead!);
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _isBootstrapping = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = error.toString().replaceFirst('StateError: ', '');
        _suggestions = const [
          'Is this a high opportunity lead?',
          'Write a personalized outreach message',
          'Give me a follow-up for 3 days later',
        ];
      });
    }
  }

  Future<void> _submitPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || _isReplying) {
      return;
    }

    setState(() {
      _messages.add({
        'isUser': true,
        'text': trimmed,
      });
      _messageController.clear();
      _isReplying = true;
    });
    _conversationHistory.add({
      'role': 'user',
      'content': trimmed,
    });
    _scrollToBottom();

    try {
      final reply = await _pitchService.sendConversation(
        systemPrompt: _systemPrompt,
        history: _conversationHistory,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add({
          'isUser': false,
          'text': reply,
        });
        _isReplying = false;
      });
      _conversationHistory.add({
        'role': 'assistant',
        'content': reply,
      });
      UserProfileRepository.instance.savePitchConversation(
        threadId: _threadId,
        title: widget.lead?.name ?? 'General pitch chat',
        messages: _conversationHistory,
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add({
          'isUser': false,
          'text':
              'I could not reach the drafting assistant right now. ${error.toString().replaceFirst('StateError: ', '')}',
        });
        _isReplying = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _lastCopiedMessage = text;
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || _lastCopiedMessage != text) {
        return;
      }
      setState(() {
        _lastCopiedMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible =
        MediaQuery.viewInsetsOf(context).bottom > 0 || _inputFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: widget.lead != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Image.asset('assets/branding/scoutify_logo_ui.png'),
                  ),
                  onPressed: () {},
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.article_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: _showTemplates,
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: _showConversationHistory,
          ),
        ],
        titleSpacing: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pitch AI',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'AI-powered outreach',
              style: TextStyle(
                color: Color(0xFF7A7A7A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        toolbarHeight: 76,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  if (widget.lead != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lead!.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.lead!.selectedCategory} • ${widget.lead!.address}',
                            style: const TextStyle(
                              color: Color(0xFF727272),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lead!.matchedGaps.isEmpty
                                ? 'No clear digital gap detected'
                                : widget.lead!.matchedGaps.join(', '),
                            style: const TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (widget.lead == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset('assets/branding/scoutify_logo_ui.png'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Generate new pitch',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 28,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Pick a lead → choose channel → send',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    height: 1.28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ..._messages.map((msg) {
                    final isUser = msg['isUser'] as bool;
                    final text = msg['text'] as String;
                    final isCopied = !isUser && _lastCopiedMessage == text;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: isUser ? null : () => _copyMessage(text),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isUser ? Colors.black : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: SelectableText(
                                text,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (!isUser)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12, left: 4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => _copyMessage(text),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCopied
                                            ? Icons.check_rounded
                                            : Icons.content_copy_rounded,
                                        size: 16,
                                        color: Color(0xFF707070),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        isCopied ? 'Copied' : 'Copy',
                                        style: TextStyle(
                                          color: Color(0xFF707070),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (_isReplying)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: _TypingIndicator(),
                    ),
                  if (!isKeyboardVisible &&
                      (_suggestions.isNotEmpty ||
                          _isBootstrapping ||
                          _bootstrapError != null)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Quick starts',
                      style: TextStyle(
                        color: Color(0xFF6E6E6E),
                        fontSize: 12,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isBootstrapping)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _suggestions.map((suggestion) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: _isReplying
                                    ? null
                                    : () => _submitPrompt(suggestion),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (_bootstrapError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _bootstrapError!,
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        focusNode: _inputFocusNode,
                        controller: _messageController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message Scoutify AI...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (_) => _submitPrompt(_messageController.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _submitPrompt(_messageController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _TemplateFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Email', 'Social', 'Phone', 'WhatsApp', 'Service'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = (category == 'All' && selected == null) ||
              category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                onSelected(category == 'All' ? null : category);
              },
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: AnimatedBuilder(
              animation: _animations[i],
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_animations[i].value * 0.7),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A8A8A),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
