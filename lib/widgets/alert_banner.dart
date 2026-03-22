import 'package:flutter/material.dart';
import '../models/weather.dart';

class AlertBanner extends StatefulWidget {
  final List<WeatherAlert> alerts;
  final Color textColor;

  const AlertBanner({
    super.key,
    required this.alerts,
    required this.textColor,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  bool _expanded = false;
  bool _dismissed = false;

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return const Color(0xFF7B1A1A);
      case 'severe':
        return const Color(0xFFC0392B);
      case 'moderate':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFFD4A017);
    }
  }

  String _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
      case 'severe':
        return '⚠️';
      case 'moderate':
        return '🔶';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.alerts.isEmpty) return const SizedBox.shrink();

    final primary = widget.alerts.first;
    final bgColor = _severityColor(primary.severity);
    const bannerText = Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_severityIcon(primary.severity),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    primary.event,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: bannerText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: bannerText.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Icon(Icons.close,
                      size: 16,
                      color: bannerText.withValues(alpha: 0.65)),
                ),
              ],
            ),
            if (!_expanded && primary.headline.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 24),
                child: Text(
                  primary.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: bannerText.withValues(alpha: 0.85),
                  ),
                ),
              ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              if (primary.description.isNotEmpty)
                Text(
                  primary.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: bannerText.withValues(alpha: 0.90),
                    height: 1.45,
                  ),
                ),
              if (primary.instruction.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Instructions: ${primary.instruction}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: bannerText.withValues(alpha: 0.80),
                  ),
                ),
              ],
              if (primary.expires.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Expires: ${primary.expires}',
                    style: TextStyle(
                      fontSize: 11,
                      color: bannerText.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              // Additional alerts count
              if (widget.alerts.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${widget.alerts.length - 1} more alert${widget.alerts.length > 2 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: bannerText.withValues(alpha: 0.80),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
