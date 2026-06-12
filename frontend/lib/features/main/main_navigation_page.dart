import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../ledger/ledger_page.dart';
import '../receipt/receipt_scan_page.dart';
import '../place/eco_place_map_page.dart';
import '../my/my_page.dart';
import '../../ranking/screen/ranking_page.dart';

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
      backgroundColor: HomePage.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: HomePage.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _moveTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'My',
          ),
        ],
      ),
    );
  }
}