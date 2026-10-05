import '../services/analysis_credits.dart';
import '../services/analysis_purchases.dart';
import '../widgets/bottom_banner.dart';
import '../services/notification_service.dart';
import '../services/update_notice.dart';
import '../widgets/update_notice_dialog.dart';
import 'package:flutter/material.dart';
import 'tarim_screen.dart';
import 'hayvancilik_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 1});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    AnalysisCredits.instance.refresh();
    AnalysisPurchases.instance.load();
    NotificationService.instance.warning.addListener(_showReminderWarning);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowUpdateNotice(),
    );
  }

  Future<void> _maybeShowUpdateNotice() async {
    if (!await UpdateNotice.shouldShowAutomatically() || !mounted) return;
    await _showUpdateNotice();
  }

  Future<void> _showUpdateNotice() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const UpdateNoticeDialog(),
    );
    await UpdateNotice.markSeen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AnalysisCredits.instance.refresh();
      AnalysisPurchases.instance.load();
    }
  }

  void _showReminderWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = NotificationService.instance.warning.value;
      if (mounted && message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.warning.removeListener(_showReminderWarning);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TarimScreen(),
      DashboardScreen(
        onShowUpdateNotice: _showUpdateNotice,
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const HayvancilikScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomBanner(),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.agriculture_outlined),
                selectedIcon: Icon(Icons.agriculture),
                label: 'Tarım',
              ),
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Hayvancılık',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
