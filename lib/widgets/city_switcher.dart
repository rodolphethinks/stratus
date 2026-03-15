import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/geocoding_service.dart';

class CitySwitcher extends StatefulWidget {
  final List<SavedLocation> locations;
  final int activeIndex;
  final void Function(int index) onSelect;
  final void Function(SavedLocation location) onAdd;
  final void Function(int index) onRemove;

  const CitySwitcher({
    super.key,
    required this.locations,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CitySwitcher> createState() => _CitySwitcherState();
}

class _CitySwitcherState extends State<CitySwitcher> {
  final TextEditingController _search = TextEditingController();
  final GeocodingService _geo = GeocodingService();
  List<SavedLocation> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final r = await _geo.search(q);
    if (mounted) setState(() { _results = r; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Search field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Search city…',
                hintStyle: TextStyle(fontSize: 15, color: const Color(0xFF1A1A2E).withValues(alpha: 0.40)),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: const Color(0xFF1A1A2E).withValues(alpha: 0.40), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search results
          if (_results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final loc = _results[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        loc.country.isNotEmpty
                            ? '${loc.name}, ${loc.country}'
                            : loc.name,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
                    trailing: const Icon(Icons.add, size: 18, color: Color(0x881A1A2E)),
                    onTap: () {
                      widget.onAdd(loc);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          if (_results.isEmpty && !_searching && _search.text.isEmpty) ...[
            // Saved locations
            ...List.generate(widget.locations.length, (i) {
              final loc = widget.locations[i];
              final isActive = i == widget.activeIndex;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: isActive
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF1A1A2E).withValues(alpha: 0.40),
                ),
                title: Text(
                  '${loc.name}, ${loc.country}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.check, size: 16, color: Color(0xFF1A1A2E))
                    : i > 0
                        ? GestureDetector(
                            onTap: () => widget.onRemove(i),
                            child: Icon(Icons.close, size: 16,
                                color: const Color(0xFF1A1A2E).withValues(alpha: 0.40)),
                          )
                        : null,
                onTap: () {
                  widget.onSelect(i);
                  Navigator.pop(context);
                },
              );
            }),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


