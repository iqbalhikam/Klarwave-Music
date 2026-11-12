import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'src/services/store.dart';
import 'src/ui/kit.dart';
import 'src/ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.klarwave.music.audio',
    androidNotificationChannelName: 'Klarwave Music',
    androidNotificationOngoing: true,
  );

  await AppStore.load();

  runApp(const ProviderScope(child: KlarwaveApp()));
}

class KlarwaveApp extends StatelessWidget {
  const KlarwaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kAccentA,
      brightness: Brightness.dark,
    ).copyWith(surface: kBg);

    return MaterialApp(
      title: 'Klarwave Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kBg,
        splashFactory: InkRipple.splashFactory,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF171526),
          contentTextStyle: const TextStyle(fontSize: 13),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(isDense: true),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kAccentB),
        ),
      ),
      home: const AppShell(),
    );
  }
}
