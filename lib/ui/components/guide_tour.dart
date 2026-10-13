import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/dinig_theme.dart';

/// Places the guide can point at. Each key is attached where that widget is
/// built; a step whose target is not on screen is skipped.
class GuideKeys {
  static final title = GlobalKey();
  static final tour = GlobalKey();
  static final sos = GlobalKey();
  static final voice = GlobalKey();
  static final location = GlobalKey();
  static final phrase = GlobalKey();
  static final reports = GlobalKey();
  static final hotlines = GlobalKey();
  static final settings = GlobalKey();
  static final hold = GlobalKey();
  static final call911 = GlobalKey();

  /// The Care Mode picture buttons, by `CareNeed.index`.
  static final care = List.generate(5, (_) => GlobalKey());
}

class GuideStep {
  final GlobalKey target;
  final String text;

  /// Runs before the target is looked up, for example to switch tabs.
  final VoidCallback? before;

  const GuideStep(this.target, this.text, {this.before});
}

/// The guided tour, the same idea as the dispatcher dashboard's: a pointer
/// glides to each target, a bubble says what it is, and the steps advance on
/// their own. The screen underneath is paused until the tour ends. The guide
/// only points; it never presses anything, so it can never send a report.
class GuideTour extends StatefulWidget {
  final List<GuideStep> steps;
  final VoidCallback onDone;

  /// Height to keep clear at the bottom of the screen (the tab bar).
  final double bottomInset;

  /// Care Mode: each line appears whole, in larger type, and stays twice as long.
  final bool calm;

  const GuideTour({
    super.key,
    required this.steps,
    required this.onDone,
    this.bottomInset = 0,
    this.calm = false,
  });

  @override
  State<GuideTour> createState() => _GuideTourState();
}

class _GuideTourState extends State<GuideTour> {
  int _index = 0;
  int _run = 0; // bumped on every step change; late callbacks check it
  Rect? _target;
  int _typed = 0;
  bool _hint = false;
  Timer? _timer;
  Timer? _hintTimer;

  String get _text => widget.steps[_index].text;
  bool get _still => widget.calm || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _goTo(int index) {
    if (index >= widget.steps.length) return widget.onDone();
    setState(() {
      _index = index;
      _typed = 0;
    });
    _enter();
  }

  void _enter() {
    if (!mounted) return;
    _timer?.cancel();
    final run = ++_run;
    final step = widget.steps[_index];
    step.before?.call();
    // The target may only exist once `before` has rebuilt the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || run != _run) return;
      final target = step.target.currentContext;
      if (target == null) return _goTo(_index + 1);
      final box = target.findRenderObject() as RenderBox;
      final overlay = context.findRenderObject();
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: _still ? Duration.zero : const Duration(milliseconds: 300),
      );
      if (!mounted || run != _run || !box.attached) return;
      setState(() {
        _target = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
      });
      _talk();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _talk() {
    if (_still) {
      setState(() => _typed = _text.length);
      return _hold();
    }
    _timer = Timer.periodic(const Duration(milliseconds: 26), (timer) {
      setState(() => _typed++);
      if (_typed >= _text.length) {
        timer.cancel();
        _hold();
      }
    });
  }

  // Long enough to read the line, then on to the next step.
  void _hold() {
    final ms = (42 * _text.length).clamp(2200, 4600).toInt() * (widget.calm ? 2 : 1);
    _timer = Timer(Duration(milliseconds: ms), () => _goTo(_index + 1));
  }

  void _showPausedHint() {
    setState(() => _hint = true);
    _hintTimer?.cancel();
    _hintTimer = Timer(
      const Duration(milliseconds: 2600),
      () => setState(() => _hint = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final controlsBottom = padding.bottom + widget.bottomInset + 12;
    // Bubbles stay above the controls and the paused hint.
    final floor = size.height - controlsBottom - 96;

    var target = _target ?? Rect.fromLTWH(size.width / 2, floor - 140, 0, 0);
    // A whole card: point at its heading, not its middle.
    if (target.height > 160) {
      target = Rect.fromLTWH(target.left, target.top, target.width, 56);
    }
    final below = target.bottom + 150 < floor;
    final tip = Offset(
      target.left + math.min(target.width / 2, 40),
      below ? target.bottom + 2 : target.top - 2,
    );
    final last = _index == widget.steps.length - 1;

    final bubble = Semantics(
      liveRegion: true,
      label: _text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 9),
        decoration: BoxDecoration(
          color: DinigColors.darkNavy,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(below ? 6 : 16),
            bottomLeft: Radius.circular(below ? 16 : 6),
            topRight: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x660B192C),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DINIG Guide',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            // The untyped rest is laid out but invisible, so the bubble does
            // not change size while the line types out.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: _text.substring(0, _typed)),
                  TextSpan(
                    text: _text.substring(_typed),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.calm ? 18 : 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pauses the screen underneath.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (_) => _showPausedHint(),
          ),
          IgnorePointer(
            child: TweenAnimationBuilder<Offset>(
              tween: Tween<Offset>(end: tip),
              duration: _still
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              builder: (context, at, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CustomSingleChildLayout(
                    delegate: _BubbleLayout(at, below, padding.top + 8, floor),
                    child: bubble,
                  ),
                  Positioned(
                    left: at.dx - _PointerPainter.tip,
                    top: at.dy - _PointerPainter.tip,
                    // Under a target the pointer aims up at it; above a
                    // target it turns to aim down.
                    child: Transform.rotate(
                      angle: below ? 0 : -math.pi / 2,
                      alignment: Alignment.topLeft,
                      origin: const Offset(
                        _PointerPainter.tip,
                        _PointerPainter.tip,
                      ),
                      child: const CustomPaint(
                        size: Size(24, 24),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hint)
            Positioned(
              left: 16,
              right: 16,
              bottom: controlsBottom + 56,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DinigColors.darkNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Paused for the tour. Tap Skip to use DINIG.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: controlsBottom,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: DinigColors.cardSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DinigColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330B192C),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous step',
                    ),
                    Semantics(
                      label: 'Step ${_index + 1} of ${widget.steps.length}',
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.steps.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: i == _index ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? DinigColors.emergencyRed
                                    : DinigColors.textSecondary.withValues(
                                        alpha: 0.35,
                                      ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: last ? null : () => _goTo(_index + 1),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next step',
                    ),
                    TextButton(
                      onPressed: widget.onDone,
                      child: Text(last ? 'Done' : 'Skip'),
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

/// Puts the bubble beside the pointer and keeps it on screen.
class _BubbleLayout extends SingleChildLayoutDelegate {
  final Offset tip;
  final bool below;
  final double top;
  final double floor;

  const _BubbleLayout(this.tip, this.below, this.top, this.floor);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: math.min(280.0, constraints.maxWidth - 24));

  @override
  Offset getPositionForChild(Size size, Size child) => Offset(
    (tip.dx + 12)
        .clamp(12, math.max(12, size.width - child.width - 12))
        .toDouble(),
    (below ? tip.dy + 18 : tip.dy - 14 - child.height)
        .clamp(top, math.max(top, floor - child.height))
        .toDouble(),
  );

  @override
  bool shouldRelayout(_BubbleLayout old) =>
      old.tip != tip || old.below != below || old.floor != floor;
}

/// The dashboard's guide cursor: a red arrow with a light rim, tip at
/// ([tip], [tip]).
class _PointerPainter extends CustomPainter {
  static const double tip = 5.5;

  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final arrow = Path()
      ..moveTo(5.5, 5.5)
      ..lineTo(9.4, 17.2)
      ..lineTo(11.6, 11.6)
      ..lineTo(17.2, 9.4)
      ..close();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      arrow,
      stroke
        ..color = DinigColors.bgCanvas
        ..strokeWidth = 6.5,
    );
    canvas.drawPath(
      arrow,
      stroke
        ..color = DinigColors.emergencyRed
        ..strokeWidth = 4,
    );
    canvas.drawPath(arrow, Paint()..color = DinigColors.emergencyRed);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
