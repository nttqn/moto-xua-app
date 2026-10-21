import 'package:flutter/material.dart';

import '../core/daily.dart';
import '../services/progress.dart';
import 'theme.dart';

/// Today's three jobs, with their progress and a button to collect each.
class DailySheet extends StatelessWidget {
  const DailySheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: paper,
    isScrollControlled: true,
    builder: (_) => const DailySheet(),
  );

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final tasks = p.dailyTasks;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('VIỆC HẰNG NGÀY',
                    textAlign: TextAlign.center,
                    style: signText.copyWith(fontSize: 22, color: signRed)),
                const SizedBox(height: 4),
                const Text('Mỗi ngày ba việc mới. Làm ở chế độ nào cũng được.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 14),
                for (var i = 0; i < tasks.length; i++) _row(p, i, tasks[i]),
                const SizedBox(height: 6),
                _bonus(p),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(Progress p, int i, DailyTask t) {
    final done = p.dailyDone(i);
    final claimed = p.dailyClaimed[i];
    final value = (p.dailyProgress[i] / t.target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ink.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 9,
                    backgroundColor: ink.withValues(alpha: 0.12),
                    color: done ? signTeal : signYellow,
                  ),
                ),
                const SizedBox(height: 3),
                Text('${p.dailyProgress[i]} / ${t.target}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: claimed
                ? const Center(
                    child: Text('ĐÃ NHẬN',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: signTeal)),
                  )
                : SignButton(
                    label: done ? 'NHẬN' : money(t.reward),
                    sub: done ? money(t.reward) : null,
                    fontSize: 15,
                    color: signTeal,
                    onTap: done ? () => p.claimDaily(i) : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bonus(Progress p) {
    if (p.dailyBonusClaimed) {
      return const Text('Đã nhận thưởng đủ ba việc hôm nay. Mai quay lại nhé!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700));
    }
    return SignButton(
      label: 'THƯỞNG ĐỦ BA VIỆC',
      sub: '+ ${money(dailyBonus)}',
      icon: Icons.card_giftcard_rounded,
      color: signRed,
      fontSize: 17,
      onTap: p.dailyBonusReady ? p.claimDailyBonus : null,
    );
  }
}

/// The calendar button on the home screen, with a dot when something is
/// waiting to be collected.
class DailyButton extends StatelessWidget {
  const DailyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final waiting = Progress.instance.dailyClaimable;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: ink.withValues(alpha: 0.85),
                foregroundColor: signYellow,
              ),
              tooltip: 'Việc hằng ngày',
              onPressed: () => DailySheet.open(context),
              icon: const Icon(Icons.event_available_rounded),
            ),
            if (waiting > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: signRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFF3C4), width: 1.5),
                  ),
                  child: Text('$waiting',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        );
      },
    );
  }
}
