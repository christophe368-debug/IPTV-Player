import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Das Wiedererkennungsmerkmal der App: ein dezent pulsierender Punkt fuer
/// alles, was gerade live/aktuell laeuft (Senderkacheln, EPG "Jetzt").
/// Bewusst zurueckhaltend animiert (langsam, kleine Amplitude) - soll ein
/// ruhiges Signal sein, keine Ablenkung.
class LivePulse extends StatefulWidget {
  final double size;
  const LivePulse({super.key, this.size = 8});

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + (widget.size * 1.4 * t),
              height: widget.size + (widget.size * 1.4 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.35 * (1 - t)),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Kleines "LIVE"-Abzeichen mit [LivePulse]-Punkt, z.B. auf Senderkacheln.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LivePulse(size: 6),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
