import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:malo/utils/app_theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<ChatSession> _sessions = [];
  List<ChatSession> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ✅ ADDED: Public refresh method
  Future<void> refresh() async {
    await _load();
  }

  Future<void> _load() async {
    final sessions = await DatabaseService.instance.getSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _filtered = sessions;
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _sessions
          : _sessions
              .where((s) =>
                  s.title.toLowerCase().contains(q) ||
                  s.modelName.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _deleteSession(String id) async {
    await DatabaseService.instance.deleteSession(id);
    await _load(); // ✅ Refresh after delete
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${DateFormat.jm().format(dt)}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  )
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat History',
            style: GoogleFonts.dmSerifDisplay(
              color: AppColors.textPrimary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty
                ? 'No conversations yet'
                : 'No results found',
            style: const TextStyle(
                color: AppColors.textSub, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isEmpty
                ? 'Start a chat to see it here'
                : 'Try a different search term',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildSessionCard(_filtered[i]),
    );
  }

  // In _buildSessionCard method:
Widget _buildSessionCard(ChatSession session) {
  // ✅ Check if model is still downloaded
  final isModelAvailable = kAvailableModels
      .where((m) => m.id == session.modelId)
      .any((m) => _isModelDownloaded(m.id));

  return Dismissible(
    key: Key(session.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.dangerDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.danger),
    ),
    onDismissed: (_) => _deleteSession(session.id),
    child: GestureDetector(
      onTap: () {
        final model = kAvailableModels.firstWhere(
          (m) => m.id == session.modelId,
          orElse: () => kAvailableModels[2],
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(model: model, existingSession: session),
          ),
        ).then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isModelAvailable ? AppColors.border : AppColors.warn.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ Show warning icon if model is missing
                if (!isModelAvailable) ...[
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 16),
                  const SizedBox(width: 4),
                ],
                const SizedBox(width: 12),
                Text(
                  _formatDate(session.updatedAt),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isModelAvailable ? AppColors.accentDim : AppColors.warn.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isModelAvailable
                          ? AppColors.accent.withOpacity(0.25)
                          : AppColors.warn.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isModelAvailable)
                        const Icon(Icons.download_outlined, size: 10, color: AppColors.warn),
                      if (!isModelAvailable) const SizedBox(width: 4),
                      Text(
                        session.modelName,
                        style: TextStyle(
                          color: isModelAvailable ? AppColors.accent : AppColors.warn,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${session.messageCount} messages',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

// ✅ Add this helper method
bool _isModelDownloaded(String modelId) {
  // This would need to be passed from parent or check DB
  // For now, we'll check if the file path exists in DB
  return true; // Placeholder - MainShell should pass downloaded IDs
}

