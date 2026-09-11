import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';

/// 1.2 — Onboarding carousel (3 slides). First install only.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      _SlideArt.skyline,
      'Rides that work for Lagos',
      'Reliable pickups, fair fares and drivers who know every street.',
    ),
    (
      _SlideArt.driver,
      'Drivers who earn fairly',
      'Our fare floor means every trip supports the person driving you.',
    ),
    (
      _SlideArt.wallet,
      'Pay your way — card, wallet or cash',
      'Top up your NaijaMove Wallet, save a card, or pay cash. Your call.',
    ),
  ];

  void _finish() {
    ref.read(sessionProvider.notifier).completeOnboarding();
    context.go(Routes.phone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final (art, title, body) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 220, child: _Illustration(art)),
                        const SizedBox(height: 40),
                        Text(
                          title,
                          style: theme.textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primaryBlue : context.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: PrimaryButton(
                label: last ? 'Get Started' : 'Next',
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SlideArt { skyline, driver, wallet }

/// Flat line-art illustrations in Primary Blue with Accent Gold highlights.
class _Illustration extends StatelessWidget {
  const _Illustration(this.art);
  final _SlideArt art;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArtPainter(art, context.tint));
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.art, this.tint);
  final _SlideArt art;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = tint;
    final gold = Paint()..color = AppColors.accentGold;
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.42, fill);

    switch (art) {
      case _SlideArt.skyline:
        // sun
        canvas.drawCircle(Offset(w * 0.72, h * 0.28), 14, gold);
        // towers
        final towers = [
          (0.22, 0.32),
          (0.32, 0.22),
          (0.42, 0.38),
          (0.52, 0.18),
          (0.62, 0.30),
          (0.72, 0.42),
        ];
        for (final (x, top) in towers) {
          final r = Rect.fromLTRB(
            w * x,
            h * top + h * 0.25,
            w * x + w * 0.07,
            h * 0.7,
          );
          canvas.drawRect(r, stroke);
          for (var y = r.top + 10; y < r.bottom - 6; y += 12) {
            canvas.drawLine(
              Offset(r.left + 5, y),
              Offset(r.right - 5, y),
              stroke..strokeWidth = 1.5,
            );
          }
          stroke.strokeWidth = 3;
        }
        // bridge
        final bridge = Path()
          ..moveTo(w * 0.1, h * 0.78)
          ..lineTo(w * 0.9, h * 0.78);
        canvas.drawPath(bridge, stroke);
        for (var i = 0; i < 6; i++) {
          final x = w * (0.15 + i * 0.14);
          canvas.drawLine(Offset(x, h * 0.78), Offset(x, h * 0.9), stroke);
          canvas.drawArc(
            Rect.fromLTRB(x, h * 0.66, x + w * 0.14, h * 0.9),
            3.14,
            3.14,
            false,
            stroke..strokeWidth = 2,
          );
          stroke.strokeWidth = 3;
        }
        _car(canvas, Offset(w * 0.45, h * 0.72), w * 0.16, stroke, gold);
      case _SlideArt.driver:
        // head + shoulders
        canvas.drawCircle(Offset(w / 2, h * 0.36), h * 0.13, stroke);
        final body = Path()
          ..moveTo(w * 0.3, h * 0.78)
          ..quadraticBezierTo(w * 0.32, h * 0.55, w * 0.5, h * 0.54)
          ..quadraticBezierTo(w * 0.68, h * 0.55, w * 0.7, h * 0.78);
        canvas.drawPath(body, stroke);
        // smile
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w / 2, h * 0.38),
            width: 26,
            height: 20,
          ),
          0.4,
          2.3,
          false,
          stroke..strokeWidth = 2.5,
        );
        stroke.strokeWidth = 3;
        // verified badge
        canvas.drawCircle(Offset(w * 0.64, h * 0.62), 13, gold);
        final tick = Path()
          ..moveTo(w * 0.64 - 6, h * 0.62)
          ..lineTo(w * 0.64 - 1, h * 0.62 + 5)
          ..lineTo(w * 0.64 + 7, h * 0.62 - 5);
        canvas.drawPath(
          tick,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
        // steering wheel hint
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w / 2, h * 0.92),
            width: w * 0.5,
            height: h * 0.3,
          ),
          3.3,
          2.8,
          false,
          stroke,
        );
      case _SlideArt.wallet:
        // phone
        final phone = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.34, h * 0.18, w * 0.32, h * 0.64),
          const Radius.circular(18),
        );
        canvas.drawRRect(phone, stroke);
        canvas.drawLine(
          Offset(w * 0.45, h * 0.24),
          Offset(w * 0.55, h * 0.24),
          stroke..strokeWidth = 2,
        );
        stroke.strokeWidth = 3;
        // wallet card
        final card = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.4, h * 0.4, w * 0.36, h * 0.2),
          const Radius.circular(8),
        );
        canvas.drawRRect(card, Paint()..color = AppColors.primaryBlue);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.44, h * 0.46, w * 0.08, h * 0.05),
            const Radius.circular(2),
          ),
          gold,
        );
        // naira sign
        final tp = TextPainter(
          text: const TextSpan(
            text: '₦',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(w * 0.64, h * 0.51));
        // coin
        canvas.drawCircle(Offset(w * 0.3, h * 0.7), 16, gold);
    }
  }

  void _car(
    Canvas canvas,
    Offset origin,
    double width,
    Paint stroke,
    Paint gold,
  ) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + width * 0.15, origin.dy - width * 0.22)
      ..lineTo(origin.dx + width * 0.65, origin.dy - width * 0.22)
      ..lineTo(origin.dx + width, origin.dy)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawCircle(
      Offset(origin.dx + width * 0.22, origin.dy + 4),
      5,
      stroke,
    );
    canvas.drawCircle(
      Offset(origin.dx + width * 0.78, origin.dy + 4),
      5,
      stroke,
    );
    canvas.drawCircle(Offset(origin.dx + width * 0.98, origin.dy - 4), 3, gold);
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) =>
      old.art != art || old.tint != tint;
}
