import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NowcastPill extends StatefulWidget {
  final String message;
  final bool isRaining;
  final Color textColor;
  final List<int> hourlyPrecip;

  const NowcastPill({
    super.key,
    required this.message,
    required this.isRaining,
    required this.textColor,
    this.hourlyPrecip = const [],
  });

  @override
  State<NowcastPill> createState() => _NowcastPillState();
}

class _NowcastPillState extends State<NowcastPill>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _heightAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isRaining
        ? const Color(0xFF5882A0)
        : const Color(0xFF5E8A70);
    final bgColor = widget.isRaining
        ? const Color(0xFFEFF4F8)
        : const Color(0xFFF0F7F3);
    // Pill always has a light background — use a fixed dark text regardless
    // of the ambient screen mood (prevents white text on light pill).
    const pillText = Color(0xFF1A2640);
    const pillTextSubtle = Color(0x661A2640);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: pillText,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: pillTextSubtle,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _heightAnim,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MiniPrecipChart(textColor: pillText, precip: widget.hourlyPrecip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder 90-min precipitation mini-chart
class _MiniPrecipChart extends StatelessWidget {
  final Color textColor;
  final List<int> precip;
  const _MiniPrecipChart({required this.textColor, required this.precip});

  @override
  Widget build(BuildContext context) {
    final bars = precip.isNotEmpty
        ? precip.map((v) => (v / 100.0).clamp(0.03, 1.0)).toList()
        : List.filled(6, 0.03);
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ...bars.map((v) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: FractionallySizedBox(
                    heightFactor: v.clamp(0.05, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.precipBlue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('90 min', style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.40),
              )),
            ],
          ),
        ],
      ),
    );
  }
}


