import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/utils/app_theme.dart';
import 'package:malo/utils/common_widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../services/download_service.dart';
import 'download_screen.dart';

class ChatScreen extends StatefulWidget {
  final LlmModel model;
  final ChatSession? existingSession;

  const ChatScreen({
    super.key,
    required this.model,
    this.existingSession,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  late ChatSession _session;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _streamingText = '';
  bool _showModelInfo = false;
  bool _loadingModel = true;
  bool _modelNotFound = false; // ✅ ADDED
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    _initSession();
    _loadModel();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    LlmService.instance.unloadModel();
    super.dispose();
  }

  Future<void> _initSession() async {
    if (widget.existingSession != null) {
      _session = widget.existingSession!;
      final msgs = await DatabaseService.instance.getMessages(_session.id);
      if (mounted) setState(() => _messages = msgs);
    } else {
      _session = ChatSession(
        id: _uuid.v4(),
        title: 'New Chat',
        modelId: widget.model.id,
        modelName: '${widget.model.name} ${widget.model.version}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService.instance.insertSession(_session);
      final welcome = ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        text: 'Hey! I\'m ${widget.model.name} ${widget.model.version} '
            'running entirely on your device 🔒\n\nNo data leaves your phone. What\'s on your mind?',
        timestamp: DateTime.now(),
      );
      await DatabaseService.instance.insertMessage(_session.id, welcome);
      if (mounted) setState(() => _messages = [welcome]);
    }
  }

  Future<void> _loadModel() async {
    // ✅ FIXED: Check if model file exists before loading
    final path = await DatabaseService.instance.getModelFilePath(widget.model.id);
    
    if (path == null || !await _fileExists(path)) {
      if (mounted) {
        setState(() {
          _loadingModel = false;
          _modelNotFound = true;
        });
      }
      return;
    }

    try {
      await LlmService.instance.loadModel(widget.model, path);
      if (mounted) setState(() => _loadingModel = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingModel = false;
          _modelNotFound = true;
        });
      }
    }
  }

  // ✅ ADDED: Check if file exists
  Future<bool> _fileExists(String path) async {
    try {
      final file = await File(path).exists();
      return file;
    } catch (_) {
      return false;
    }
  }

  void _reDownloadModel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DownloadScreen(model: widget.model),
      ),
    );
  }

  void _sendMessage() {
    if (_modelNotFound) {
      _showModelMissingDialog();
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping || _loadingModel) return;
    _textController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _streamingText = '';
    });

    DatabaseService.instance.insertMessage(_session.id, userMsg);
    _scrollToBottom();

    if (_session.messageCount == 0) {
      _session.title = text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    _session.messageCount++;
    _session.updatedAt = DateTime.now();
    DatabaseService.instance.updateSession(_session);

    _streamSub = LlmService.instance.sendMessage(text).listen(
      (token) {
        if (mounted) {
          setState(() => _streamingText += token);
          _scrollToBottom();
        }
      },
      onDone: () async {
        if (!mounted) return;
        final aiMsg = ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          text: _streamingText,
          timestamp: DateTime.now(),
        );
        await DatabaseService.instance.insertMessage(_session.id, aiMsg);
        _session.messageCount++;
        _session.updatedAt = DateTime.now();
        await DatabaseService.instance.updateSession(_session);
        setState(() {
          _messages.add(aiMsg);
          _isTyping = false;
          _streamingText = '';
        });
        _scrollToBottom();
      },
      onError: (_) {
        if (mounted) setState(() => _isTyping = false);
      },
    );
  }

  // ✅ ADDED: Show dialog when model is missing
  void _showModelMissingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Model Not Found',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${widget.model.name} ${widget.model.version} has been deleted from your device. '
          'You need to re-download it to continue this conversation.',
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _reDownloadModel();
            },
            child: const Text('Re-download'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          if (_showModelInfo) _buildModelInfoBar(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios, color: AppColors.textSub, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GlowDot(
                      color: AppColors.success,
                      size: 8,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.model.name} ${widget.model.version}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _loadingModel
                      ? 'Loading model...'
                      : _modelNotFound
                          ? '⚠️ Model not found on device'
                          : '🔒 Fully offline · ${widget.model.tokensPerSec}',
                  style: TextStyle(
                    color: _modelNotFound ? AppColors.warn : AppColors.textSub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showModelInfo = !_showModelInfo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('⋯', style: TextStyle(color: AppColors.textSub, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfoBar() {
    final items = [
      ['Quantization', widget.model.quant],
      ['RAM Usage', widget.model.ram],
      ['Speed', widget.model.tokensPerSec],
      ['Context', '32K tokens'],
    ];
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item[0].toUpperCase(),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(item[1],
                style: GoogleFonts.dmMono(
                    color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loadingModel) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Loading model into memory...',
                style: TextStyle(color: AppColors.textSub, fontSize: 13)),
          ],
        ),
      );
    }

    // ✅ FIXED: Show model missing state
    if (_modelNotFound) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '${widget.model.name} ${widget.model.version}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This model has been deleted from your device.\nRe-download to continue chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _reDownloadModel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF00C4B4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '📥 Re-download Model',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) return _buildStreamingBubble();
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.surface,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.accentDim : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isUser ? AppColors.accent.withOpacity(0.35) : AppColors.border,
                  ),
                ),
                child: MarkdownBody(
                  data: msg.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    code: TextStyle(
                      backgroundColor: AppColors.surface,
                      color: AppColors.accent,
                      fontFamily: 'monospace',
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildStreamingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: _streamingText.isEmpty
                  ? const _TypingDotsWidget()
                  : MarkdownBody(
                      data: _streamingText,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentDim,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(fontSize: 12, color: AppColors.accent)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 1,
                    enabled: !_modelNotFound && !_loadingModel, // ✅ Disable if model missing
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _modelNotFound
                          ? 'Model not available'
                          : 'Message your offline AI...',
                      hintStyle: TextStyle(
                        color: _modelNotFound ? AppColors.textMuted : AppColors.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: _modelNotFound ? _showModelMissingDialog : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _textController.text.isNotEmpty && !_isTyping && !_modelNotFound
                            ? const LinearGradient(colors: [AppColors.accent, Color(0xFF00B8A3)])
                            : null,
                        color: _textController.text.isEmpty || _isTyping || _modelNotFound
                            ? AppColors.border
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: _textController.text.isNotEmpty && !_isTyping && !_modelNotFound
                            ? Colors.black
                            : AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modelNotFound
                ? '⚠️ Model deleted - Re-download to continue'
                : '🔒 Running offline on ${widget.model.name} ${widget.model.version}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget();

  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
          final opacity = t < 0.5 ? t * 2 : (1.0 - t) * 2;
          return Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(opacity.clamp(0.3, 1.0)),
            ),
          );
        }),
      ),
    );
  }
}
