import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ads_service.dart';
import 'services/progress.dart';
import 'services/sound_service.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The road and the touch zones are laid out for a tall screen.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Not awaited: a slow or broken audio asset must never delay the first frame.
  SoundService.instance.init();
  SoundService.instance.playMenuMusic();
  AdsService.instance.initialize();
  await Progress.instance.load();
  runApp(const MotoXuaApp());
}

class MotoXuaApp extends StatelessWidget {
  const MotoXuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xe Xưa',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
