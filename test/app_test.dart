import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/content.dart';
import 'package:moto_xua/main.dart';
import 'package:moto_xua/services/progress.dart';
import 'package:moto_xua/ui/ride_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A Flame GameWidget never settles, so these pump fixed durations.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home leads to the stage list', (tester) async {
    await tester.pumpWidget(const MotoXuaApp());
    await tester.pump(const Duration(milliseconds: 200));
    for (final label in ['CHẠY VÔ TẬN', 'ĐUA CHẶNG', 'NHIỆM VỤ', 'GARA']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('ĐUA CHẶNG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(stages.first.title), findsOneWidget);
  });

  testWidgets('back pauses a ride instead of leaving it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RideScreen(
        config: missionConfig(0),
        title: missions.first.title,
        missionIndex: 0,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('TẠM DỪNG'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TẠM DỪNG'), findsOneWidget);
    expect(find.byType(RideScreen), findsOneWidget);
    await tester.tap(find.text('CHẠY TIẾP'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TẠM DỪNG'), findsNothing);
  });

  test('buying and upgrading spend money and stick', () async {
    final p = Progress.instance;
    p.coins = 100000;
    final before = p.stats.topSpeed;
    expect(p.buy(p.selected), isFalse, reason: 'already owned');
    expect(p.upgrade(p.selected, p.parts[p.selected]!.keys.first), isTrue);
    expect(p.stats.topSpeed, greaterThan(before));
    expect(p.coins, lessThan(100000));
  });

  test('a mission pays in full once, then a quarter', () {
    final p = Progress.instance;
    final start = p.coins;
    expect(p.recordMission(2, 2), missions[2].reward);
    expect(p.recordMission(2, 3), (missions[2].reward * 0.25).round());
    expect(p.missionStars[2], 3);
    expect(p.coins, start + missions[2].reward + (missions[2].reward * 0.25).round());
    expect(p.missionUnlocked(3), isTrue);
  });
}
