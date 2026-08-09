import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/finn_tokens.dart';
import '../services/sfx.dart';

/// Pastki navigatsiya — bead (marvarid) uslubida.
///
/// Xatti-harakat (dizayn: finn-app-full.html .nav/.bead/.tab):
///  • Aktiv ikonka bead (dumaloq) ichiga 19px ko'tariladi (oq bo'ladi).
///  • Har ikonka ALOHIDA bosiladi — bosilgan menyu ochiladi (sakramaydi).
///  • Bead'ni surganda har yangi menyuga o'tganda "pop" ovoz chiqadi.
class FinnNavItem {
  const FinnNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class FinnBeadNav extends StatefulWidget {
  const FinnBeadNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<FinnNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  static const double barHeight = 64;
  static const double beadSize = 52;
  static const double beadLift = 16;
  static const double notchGap = 7;
  static const double sidePad = 14;
  static const double innerPad = 8;

  static double get totalHeight => barHeight + beadLift + 4;

  @override
  State<FinnBeadNav> createState() => _FinnBeadNavState();
}

class _FinnBeadNavState extends State<FinnBeadNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _pos;
  double _dragPos = -1;
  bool _dragging = false;
  int _lastCross = -1;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: FinnTokens.beadDur);
    _pos = AlwaysStoppedAnimation(widget.index.toDouble());
  }

  @override
  void didUpdateWidget(covariant FinnBeadNav old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !_dragging) {
      _animateTo(widget.index.toDouble());
    }
  }

  void _animateTo(double target) {
    _pos = Tween<double>(begin: _pos.value, end: target)
        .animate(CurvedAnimation(parent: _c, curve: FinnTokens.bead));
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _slot(double w) =>
      (w - FinnBeadNav.innerPad * 2) / widget.items.length;
  double _center(double p, double w) =>
      FinnBeadNav.innerPad + (p + 0.5) * _slot(w);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final inset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
          left: FinnBeadNav.sidePad,
          right: FinnBeadNav.sidePad,
          bottom: 20 + inset),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final p = _dragging ? _dragPos : _pos.value;
            final cx = _center(p, w);
            final active = p.round().clamp(0, widget.items.length - 1);

            // Bead'ni surish — faqat gorizontal drag (tap ikonkalarga tegadi).
            void dragStart(DragStartDetails d) {
              _dragging = true;
              _dragPos = _pos.value;
              _lastCross = _pos.value.round();
              setState(() {});
            }

            void dragUpdate(DragUpdateDetails d) {
              final slot = _slot(w);
              final raw = (d.localPosition.dx - FinnBeadNav.innerPad) / slot - 0.5;
              final np = raw.clamp(0, (widget.items.length - 1).toDouble());
              final cross = np.round();
              if (cross != _lastCross) {
                _lastCross = cross;
                Sfx.i.pop(); // har yangi menyuga o'tganda ovoz
                HapticFeedback.selectionClick();
              }
              setState(() => _dragPos = np.toDouble());
            }

            void dragEnd(DragEndDetails _) {
              final target = _dragPos.round();
              _dragging = false;
              _animateTo(target.toDouble());
              widget.onChanged(target);
            }

            return GestureDetector(
              // Faqat gorizontal drag — tap'lar ichki ikonkalarga o'tadi.
              behavior: HitTestBehavior.deferToChild,
              onHorizontalDragStart: dragStart,
              onHorizontalDragUpdate: dragUpdate,
              onHorizontalDragEnd: dragEnd,
              child: SizedBox(
                height: FinnBeadNav.totalHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── panel (kesma bilan) ──
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: FinnBeadNav.barHeight,
                      child: ClipPath(
                        clipper: _NotchClipper(
                          notchCenterX: cx,
                          notchCenterY: -(FinnBeadNav.beadLift) +
                              FinnBeadNav.beadSize / 2,
                          notchRadius:
                              FinnBeadNav.beadSize / 2 + FinnBeadNav.notchGap,
                          radius: 32,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(t.glass, t.bg),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: t.line, width: 1),
                          ),
                        ),
                      ),
                    ),

                    // ── bead ── (dizayn: bar tepasidan 16px chiqadi, markazi
                    // bar tepasidan 10px pastda — ikonka bilan mos keladi)
                    Positioned(
                      left: cx - FinnBeadNav.beadSize / 2,
                      bottom: FinnBeadNav.barHeight +
                          FinnBeadNav.beadLift -
                          FinnBeadNav.beadSize,
                      width: FinnBeadNav.beadSize,
                      height: FinnBeadNav.beadSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: FinnTokens.brand,
                          border: Border.all(color: t.line, width: 1),
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 8),
                              blurRadius: 20,
                              color: const Color(0xFF1745C9)
                                  .withValues(alpha: _dragging ? 0.55 : 0.42),
                            ),
                          ],
                        ),
                        child: const _BeadHighlight(),
                      ),
                    ),

                    // ── ikonkalar (har biri alohida bosiladi) ──
                    for (var i = 0; i < widget.items.length; i++)
                      Positioned(
                        left: _center(i.toDouble(), w) - _slot(w) / 2,
                        width: _slot(w),
                        bottom: 0,
                        height: FinnBeadNav.totalHeight,
                        child: _Tab(
                          item: widget.items[i],
                          active: i == active,
                          tokens: t,
                          onTap: () => widget.onChanged(i),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Bitta tab — aktivda ikonka 19px bead ichiga ko'tariladi (oq), yorliq chiqadi.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  final FinnNavItem item;
  final bool active;
  final FinnTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ikonka — bar markazida (pastdan ~32px), aktivda 19px yuqoriga.
          Positioned(
            bottom: 22,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: active ? 1 : 0),
              duration: FinnTokens.beadDur,
              curve: FinnTokens.bead,
              builder: (_, v, __) => Transform.translate(
                offset: Offset(0, -22 * v),
                child: Transform.scale(
                  scale: 1 + 0.06 * v,
                  child: Icon(item.icon,
                      size: 20,
                      color: Color.lerp(tokens.ink3, Colors.white, v)),
                ),
              ),
            ),
          ),
          // yorliq — pastda, faqat aktivda.
          Positioned(
            bottom: 9,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(item.label,
                  maxLines: 1,
                  style: FinnText.navLabel(tokens.blue)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beadning yuqori qirrasidagi oq yorug'lik.
class _BeadHighlight extends StatelessWidget {
  const _BeadHighlight();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-0.35, -0.6),
          end: const Alignment(0.2, 0.4),
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.58],
        ),
      ),
    );
  }
}

/// Panelda dumaloq kesma ochadi (yumaloq to'rtburchakdan doira ayiriladi).
class _NotchClipper extends CustomClipper<Path> {
  _NotchClipper({
    required this.notchCenterX,
    required this.notchCenterY,
    required this.notchRadius,
    required this.radius,
  });

  final double notchCenterX;
  final double notchCenterY;
  final double notchRadius;
  final double radius;

  @override
  Path getClip(Size size) {
    final panel = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    final notch = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(notchCenterX, notchCenterY),
        radius: notchRadius,
      ));
    return Path.combine(PathOperation.difference, panel, notch);
  }

  @override
  bool shouldReclip(covariant _NotchClipper old) =>
      old.notchCenterX != notchCenterX ||
      old.notchRadius != notchRadius ||
      old.notchCenterY != notchCenterY;
}
