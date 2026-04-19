import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malo/utils/app_theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import 'model_select_screen.dart';
import 'history_screen.dart';
import 'library_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<String> _downloadedModelIds = [];
  
  // ✅ ADDED: Global keys to trigger refresh
  final _historyKey = GlobalKey<HistoryScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadDownloadedModels();
  }

  Future<void> _loadDownloadedModels() async {
    final ids = await DatabaseService.instance.getDownloadedModelIds();
    if (mounted) setState(() => _downloadedModelIds = ids);
  }

  // ✅ ADDED: Public refresh method for child screens to call
  Future<void> refreshAll() async {
    await _loadDownloadedModels();
    _historyKey.currentState?.refresh();
    _libraryKey.currentState?.refresh();
  }

  void _onModelUse(LlmModel model) {
    refreshAll(); // ✅ Refresh when model is used
    setState(() => _currentIndex = 2);
  }

  void _navigateToModels() {
    setState(() => _currentIndex = 0);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return ModelsScreen(onDownloadComplete: refreshAll);
      case 1:
        return HistoryScreen(key: _historyKey);
      case 2:
        return LibraryScreen(
          key: _libraryKey,
          downloadedModelIds: _downloadedModelIds,
          onRefresh: refreshAll,
          onNavigateToModels: _navigateToModels,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(3, (i) => _buildScreen(i)),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(label: 'Models', icon: '⬇', index: 0),
      _NavItem(label: 'History', icon: '🕐', index: 1),
      _NavItem(label: 'Library', icon: '📦', index: 2),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.map((item) {
              final active = _currentIndex == item.index;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // ✅ Refresh data when switching tabs
                    if (_currentIndex != item.index) {
                      setState(() => _currentIndex = item.index);
                      await Future.delayed(const Duration(milliseconds: 300));
                      refreshAll();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: active ? 22 : 20,
                        ),
                        child: Text(item.icon),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? AppColors.accent : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 4 : 0,
                        height: active ? 4 : 0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String icon;
  final int index;
  const _NavItem({required this.label, required this.icon, required this.index});
}
