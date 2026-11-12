import 'package:flutter/material.dart';

import 'home.dart';
import 'kit.dart';
import 'library.dart';
import 'player.dart';
import 'search.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _index,
                children: const [HomePage(), SearchPage(), LibraryPage()],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniPlayer(onOpen: () => openPlayer(context)),
                    const SizedBox(height: 8),
                    GlassNav(
                      index: _index,
                      onChanged: (i) => setState(() => _index = i),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
