import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class RadarMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Color textColor;

  const RadarMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.textColor,
  });

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  String? _radarPath;
  String? _radarHost;
  bool _loading = true;
  bool _error = false;
  DateTime? _radarTime;

  @override
  void initState() {
    super.initState();
    _fetchRadarFrame();
  }

  Future<void> _fetchRadarFrame() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) throw Exception('RainViewer error');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final host = data['host'] as String? ?? 'https://tilecache.rainviewer.com';
      final past = (data['radar']?['past'] as List?) ?? [];

      if (past.isEmpty) throw Exception('No radar frames');

      final latest = past.last as Map<String, dynamic>;
      final path = latest['path'] as String;
      final timestamp = latest['time'] as int;

      if (mounted) {
        setState(() {
          _radarHost = host;
          _radarPath = path;
          _radarTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  String _timeAgo() {
    if (_radarTime == null) return '';
    final diff = DateTime.now().difference(_radarTime!);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text('RADAR', style: AppTextStyles.sectionLabel(widget.textColor)),
            const SizedBox(width: 8),
            if (_radarTime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.textColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LIVE · ${_timeAgo()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            if (!_loading && !_error)
              GestureDetector(
                onTap: () {
                  setState(() { _loading = true; _error = false; });
                  _fetchRadarFrame();
                },
                child: Icon(Icons.refresh,
                    size: 16,
                    color: widget.textColor.withValues(alpha: 0.45)),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Map container
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: widget.textColor.withValues(alpha: 0.40),
                    ),
                  )
                : _error
                    ? _buildError()
                    : _buildMap(),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      color: widget.textColor.withValues(alpha: 0.05),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off,
                size: 28, color: widget.textColor.withValues(alpha: 0.35)),
            const SizedBox(height: 8),
            Text(
              'Radar unavailable',
              style: TextStyle(
                fontSize: 13,
                color: widget.textColor.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final tileUrl =
        '${_radarHost!}${_radarPath!}/512/{z}/{x}/{y}/2/1_1.png';

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: 7.5,
        minZoom: 4.0,
        maxZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // Base map (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'app.stratus.weather',
        ),
        // RainViewer precipitation overlay
        Opacity(
          opacity: 0.65,
          child: TileLayer(
            urlTemplate: tileUrl,
          ),
        ),
        // Location pin  
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.latitude, widget.longitude),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
        // Attribution (OSM license requirement)
        SimpleAttributionWidget(
          source: const Text(
            '© OpenStreetMap · RainViewer',
            style: TextStyle(fontSize: 9),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}
