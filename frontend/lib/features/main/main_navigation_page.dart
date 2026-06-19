import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/eco_design_system.dart';
import '../home/home_page.dart';
import '../ledger/ledger_page.dart';
import '../receipt/receipt_scan_page.dart';
import '../place/eco_place_map_page.dart';
import '../my/my_page.dart';
import '../ranking/screen/ranking_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  void _moveTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openEcoPlaceMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EcoPlaceMapPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        userId: widget.user.uid,
        onTapScan: () {
          _moveTab(2);
        },
        onTapEcoPlaceMap: _openEcoPlaceMap,
      ),
      LedgerPage(
        userId: widget.user.uid,
        onTapScan: () {
          _moveTab(2);
        },
      ),
      ReceiptScanPage(userId: widget.user.uid),
      RankingPage(currentUserId: widget.user.uid),
      MyPage(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: EcoColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      extendBody: true,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: EcoColors.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? EcoColors.secondary : EcoColors.muted,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? EcoColors.secondary : EcoColors.muted,
            );
          }),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EcoShadow.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 76,
            selectedIndex: _currentIndex,
            onDestinationSelected: _moveTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: '가계부',
              ),
              NavigationDestination(
                icon: _ScanNavIcon(),
                label: '스캔',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events_rounded),
                label: '랭킹',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '마이',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanNavIcon extends StatelessWidget {
  const _ScanNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: EcoColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.document_scanner_outlined,
        color: Colors.white,
        size: 23,
      ),
    );
  }
}
