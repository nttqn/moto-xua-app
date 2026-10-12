import 'package:flutter/material.dart';

import '../core/bikes.dart';
import '../core/content.dart';
import '../core/track.dart';
import '../services/progress.dart';
import 'ride_screen.dart';
import 'theme.dart';

/// One row of a stage or mission list.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.number,
    required this.title,
    required this.lines,
    required this.stars,
    required this.locked,
    required this.pay,
    required this.onTap,
  });

  final int number;
  final String title;
  final List<String> lines;
  final int stars;
  final bool locked;
  final int pay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Card(
        color: Colors.white.withValues(alpha: 0.75),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ink.withValues(alpha: 0.35), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: locked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locked ? const Color(0xFF9A9284) : signRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: locked
                      ? const Icon(Icons.lock_rounded, color: Colors.white)
                      : Text('$number',
                          style: signText.copyWith(
                              color: const Color(0xFFFFF3C4), fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      for (final l in lines)
                        if (l.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(l, style: const TextStyle(fontSize: 13)),
                          ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Stars(stars),
                    const SizedBox(height: 6),
                    Text(money(pay),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A5F06))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

AppBar _bar(String title) => AppBar(
  title: Text(title),
  actions: const [
    Padding(
      padding: EdgeInsets.only(right: 10),
      child: Center(child: CoinChip()),
    ),
  ],
);

class StagesScreen extends StatelessWidget {
  const StagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = Progress.instance;
    return Scaffold(
      appBar: _bar('ĐUA CHẶNG'),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: stages.length + 1,
          itemBuilder: (context, row) {
            if (row == 0) return _riding();
            final i = row - 1;
            final s = stages[i];
            return _Entry(
              number: i + 1,
              title: s.title,
              lines: [
                '${themeNames[s.theme]} · ${s.km.toStringAsFixed(1)} km'
                    '${s.twoWay ? ' · hai chiều' : ''}'
                    '${s.dusk ? ' · chiều tà' : ''}',
                'Đối thủ: ${bikeSpec(s.bike).name}'
                    '${s.rivalLevel > 0 ? ' độ cấp ${s.rivalLevel}' : ''}'
                    '${s.fast != null ? ', có ${bikeSpec(s.fast!).name}' : ''}',
              ],
              stars: progress.stageStars[i],
              locked: !progress.stageUnlocked(i),
              pay: s.prize,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RideScreen(
                  config: stageConfig(i),
                  title: s.title,
                  stageIndex: i,
                ),
              )),
            );
          },
        ),
      ),
    );
  }
}

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = Progress.instance;
    return Scaffold(
      appBar: _bar('NHIỆM VỤ'),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: missions.length + 1,
          itemBuilder: (context, row) {
            if (row == 0) return _riding();
            final i = row - 1;
            final m = missions[i];
            return _Entry(
              number: i + 1,
              title: m.title,
              lines: [
                m.brief,
                '${m.goalText}${m.ruleText.isEmpty ? '' : ' · ${m.ruleText}'}',
                '${themeNames[m.theme]} · hợp với ${bikeSpec(m.bike).name}',
              ],
              stars: progress.missionStars[i],
              locked: !progress.missionUnlocked(i),
              pay: m.reward,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RideScreen(
                  config: missionConfig(i),
                  title: m.title,
                  missionIndex: i,
                ),
              )),
            );
          },
        ),
      ),
    );
  }
}

Widget _riding() => Padding(
  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
  child: Text('Đang đi: ${bikeLine()}',
      style: const TextStyle(fontWeight: FontWeight.w700)),
);
