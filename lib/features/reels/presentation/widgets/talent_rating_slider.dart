import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';

/// Rating slider 0–10, step 0.5 — matches .reel-rating-panel__slider / .rating-sheet__slider.
class TalentRatingSlider extends StatefulWidget {
  const TalentRatingSlider({
    super.key,
    this.initialValue = 5,
    this.onChanged,
    this.compact = false,
  });

  final double initialValue;
  final ValueChanged<double>? onChanged;
  final bool compact;

  @override
  State<TalentRatingSlider> createState() => _TalentRatingSliderState();
}

class _TalentRatingSliderState extends State<TalentRatingSlider> {
  late double _value;

  static const _trackGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D57),
      Color(0xFFFF9500),
      Color(0xFFFFD93D),
      Color(0xFF4ED07C),
    ],
    stops: [0, 0.32, 0.58, 1],
  );

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumbSize = 22.0;
        final trackWidth = constraints.maxWidth;
        final pct = _value / 10;
        final bubbleLeft = thumbSize / 2 + pct * (trackWidth - thumbSize);

        return Column(
          children: [
            SizedBox(
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: bubbleLeft.clamp(0, trackWidth - 40),
                    child: Transform.translate(
                      offset: const Offset(-20, 0),
                      child: _RatingBubble(value: _value.toStringAsFixed(1)),
                    ),
                  ),
                ],
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: _trackGradient,
                    ),
                  ),
                  Slider(
                    value: _value,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    onChanged: (v) {
                      setState(() => _value = v);
                      widget.onChanged?.call(v);
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                11,
                (i) => Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.compact ? 15 : 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: widget.compact ? 13 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                children: [
                  const TextSpan(text: 'Your Score: '),
                  TextSpan(
                    text: _value.toStringAsFixed(1),
                    style: AppTextStyles.displayBold15.copyWith(
                      fontSize: widget.compact ? 15.5 : 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(text: '/10'),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '0.5 step rating (Ex: 7.5, 8.0, 8.5, 9.0, 9.5)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _RatingBubble extends StatelessWidget {
  const _RatingBubble({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            value,
            style: AppTextStyles.displaySemiBold135.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              color: const Color(0xFF170B33),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(8, 4),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RatingPanelHeader extends StatelessWidget {
  const RatingPanelHeader({
    super.key,
    required this.impact,
    this.compact = false,
  });

  final int impact;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 15, color: Color(0xFFFFC933)),
                    const SizedBox(width: 6),
                    Text(
                      'RATE THIS TALENT',
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Your score helps real talent shine!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _ImpactBadge(impact: impact, compact: true),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 16, color: Color(0xFFFFC933)),
            const SizedBox(width: 7),
            Text(
              'RATE THIS TALENT',
              style: AppTextStyles.displaySemiBold135.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your score helps real talent shine!',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.impact, this.compact = false});

  final int impact;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: compact ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact',
            style: TextStyle(
              fontSize: compact ? 9.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          Text(
            '🔥 $impact',
            style: TextStyle(
              fontSize: compact ? 13 : 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingSubmitButton extends StatelessWidget {
  const RatingSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Text(label, style: AppTextStyles.displaySemiBold15),
            ),
          ),
        ),
      ),
    );
  }
}

class RatingSuccessBadge extends StatelessWidget {
  const RatingSuccessBadge({super.key, required this.score, this.large = false});

  final String score;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 78.0 : 62.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.button,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D77).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        score,
        style: TextStyle(
          fontFamily: AppTextStyles.displayBold15.fontFamily,
          fontWeight: FontWeight.w900,
          fontSize: large ? 26 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
