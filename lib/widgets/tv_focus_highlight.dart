import 'package:flutter/material.dart';

/// Umrandet sein Kind sichtbar, sobald es per Tastatur/D-Pad/Fernbedienung
/// fokussiert ist. Flutters Standard-Fokusanzeige ist auf einem Fernseher
/// aus mehreren Metern Entfernung kaum zu erkennen - ohne das hier weiss
/// man beim Navigieren mit der Fernbedienung nicht, wo man gerade ist.
///
/// Auf Touch-Geraeten faellt das kaum auf (Fokus wird dort selten sichtbar
/// gesetzt), stoert also nicht.
class TvFocusHighlight extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const TvFocusHighlight({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<TvFocusHighlight> createState() => _TvFocusHighlightState();
}

class _TvFocusHighlightState extends State<TvFocusHighlight> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Focus(
      onFocusChange: (focused) => setState(() => _hasFocus = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: _hasFocus ? color : Colors.transparent,
            width: 3,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
