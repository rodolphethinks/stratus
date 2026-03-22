import 'package:flutter/material.dart';
import '../services/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _store = SettingsStore();
  AppMode _mode = AppMode.simple;
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _store.getMode();
    final settings = await _store.getSettings();
    if (mounted) {
      setState(() {
        _mode = mode;
        _settings = settings;
        _loaded = true;
      });
    }
  }

  Future<void> _setMode(AppMode m) async {
    setState(() => _mode = m);
    await _store.setMode(m);
  }

  Future<void> _update(AppSettings s) async {
    setState(() => _settings = s);
    await _store.saveSettings(s);
  }

  static const _textColor = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: _textColor,
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),

            if (!_loaded)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),

            if (_loaded)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('MODE'),
                      const SizedBox(height: 12),
                      _buildModeToggle(),
                      const SizedBox(height: 28),

                      // Mode-specific options
                      if (_mode == AppMode.simple) ...[
                        _sectionTitle('SIMPLE MODE OPTIONS'),
                        const SizedBox(height: 4),
                        _ToggleRow(
                          label: 'Best time outside',
                          subtitle: 'Suggests the best window for outdoor activity',
                          value: _settings.showBestTimeCard,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showBestTimeCard: v)),
                        ),
                        _ToggleRow(
                          label: 'Forecast confidence',
                          subtitle: 'Shows how reliable the 7-day forecast is',
                          value: _settings.showConfidenceStrip,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showConfidenceStrip: v)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_mode == AppMode.enthusiast) ...[
                        _sectionTitle('ENTHUSIAST OPTIONS'),
                        const SizedBox(height: 4),
                        _ToggleRow(
                          label: 'Current conditions detail',
                          subtitle: 'Wind, humidity, UV index & pressure',
                          value: _settings.showMetricsRow,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showMetricsRow: v)),
                        ),
                        _ToggleRow(
                          label: 'Astronomy',
                          subtitle: 'Sunrise, sunset times and moon phase',
                          value: _settings.showAstronomy,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showAstronomy: v)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _sectionTitle('GENERAL'),
                      const SizedBox(height: 4),
                      _ToggleRow(
                        label: 'Yesterday in forecast',
                        subtitle: 'Compare today with the previous day',
                        value: _settings.showYesterday,
                        onChanged: (v) =>
                            _update(_settings.copyWith(showYesterday: v)),
                      ),
                      _ToggleRow(
                        label: 'Sunrise & sunset on chart',
                        subtitle: 'Colour markers on the hourly strip',
                        value: _settings.showSunriseSunset,
                        onChanged: (v) =>
                            _update(_settings.copyWith(showSunriseSunset: v)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Color(0x881A1A2E),
        ),
      );

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEE8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeButton(
            label: 'Simple',
            subtitle: 'Clean & essential',
            selected: _mode == AppMode.simple,
            onTap: () => _setMode(AppMode.simple),
          ),
          _ModeButton(
            label: 'Enthusiast',
            subtitle: 'Full detail',
            selected: _mode == AppMode.enthusiast,
            onTap: () => _setMode(AppMode.enthusiast),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1A1A2E)
                      : const Color(0x881A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? const Color(0x881A1A2E)
                      : const Color(0x441A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0x661A1A2E),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }
}
