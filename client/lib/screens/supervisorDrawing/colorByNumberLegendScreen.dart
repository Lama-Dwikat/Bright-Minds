import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:bright_minds/theme/colors.dart';
import '../../services/drawingApi.dart';

class ColorByNumberLegendScreen extends StatefulWidget {
  final String activityId;
  const ColorByNumberLegendScreen({super.key, required this.activityId});

  @override
  State<ColorByNumberLegendScreen> createState() =>
      _ColorByNumberLegendScreenState();
}

class _ColorByNumberLegendScreenState extends State<ColorByNumberLegendScreen> {
  bool _loading = true;
  bool _saving = false;

  String? _token;
  String? _baseUrl;

  Map<String, dynamic>? _activity;
  int _regionsCount = 0;

  final List<Map<String, dynamic>> _legend = [];

  final List<Color> _quickColors = const [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF111827),
    Color(0xFF6B7280),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    _baseUrl = prefs.getString("backendUrl") ?? "http://10.0.2.2:3000";

    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final api = DrawingApi(baseUrl: _baseUrl!);
      final activity = await api.getActivityById(
        token: _token!,
        activityId: widget.activityId,
      );

      _activity = activity;

      _regionsCount = (activity["regionsCount"] ?? 0) is int
          ? (activity["regionsCount"] ?? 0) as int
          : int.tryParse("${activity["regionsCount"]}") ?? 0;

      final legendRaw = (activity["legend"] ?? []) as List;

      _legend.clear();
      if (legendRaw.isEmpty) {
        for (int i = 0; i < _regionsCount; i++) {
          final num = i + 1;
          _legend.add({"number": num, "colorHex": "#FF0000"});
        }
      } else {
        for (final e in legendRaw) {
          _legend.add({
            "number": e["number"],
            "colorHex": (e["colorHex"] ?? "#FF0000").toString(),
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll("#", "").toUpperCase();
    final safe = h.length == 6 ? h : "FF0000";
    return Color(int.parse("FF$safe", radix: 16));
  }

  String _colorToHex(Color c) {
    final hex = c.value.toRadixString(16).padLeft(8, '0');
    return "#${hex.substring(2).toUpperCase()}";
  }

  Future<void> _pickColor(int index) async {
    final current = _hexToColor(_legend[index]["colorHex"].toString());
    Color picked = current;
    int mode = 0;

    final result = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final screenH = MediaQuery.of(sheetCtx).size.height;
        final sheetH = screenH * 0.82;

        Widget segmentButton({
          required String text,
          required int value,
          required IconData icon,
          required void Function() onTap,
        }) {
          final active = mode == value;
          return Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.bgWarmPink.withOpacity(0.18)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? Colors.black87 : Colors.black12,
                    width: active ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SizedBox(
              height: sheetH,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          "Pick color • ${_legend[index]["number"]}",
                          style: GoogleFonts.robotoSlab(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: picked,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        segmentButton(
                          text: "Quick",
                          value: 0,
                          icon: Icons.grid_view_rounded,
                          onTap: () => setLocal(() => mode = 0),
                        ),
                        const SizedBox(width: 10),
                        segmentButton(
                          text: "Picker",
                          value: 1,
                          icon: Icons.color_lens_rounded,
                          onTap: () => setLocal(() => mode = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: mode == 0
                          ? SingleChildScrollView(
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _quickColors.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemBuilder: (_, i) {
                                  final c = _quickColors[i];
                                  final selected = c.value == picked.value;

                                  return InkWell(
                                    onTap: () => setLocal(() => picked = c),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected ? Colors.black : Colors.black12,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: (c.value == 0xFFFFFFFF)
                                          ? const Center(
                                              child: Icon(
                                                Icons.check_box_outline_blank,
                                                size: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ColorPicker(
                                          pickerColor: picked,
                                          onColorChanged: (c) => setLocal(() => picked = c),
                                          enableAlpha: false,
                                          showLabel: false,
                                          displayThumbColor: true,
                                          paletteType: PaletteType.hsv,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(sheetCtx, picked),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgWarmPink,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check),
                        label: Text(
                          "Apply",
                          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _legend[index]["colorHex"] = _colorToHex(result);
      });
    }
  }

  Future<void> _saveLegend() async {
    if (_token == null || _baseUrl == null) return;

    setState(() => _saving = true);
    try {
      final api = DrawingApi(baseUrl: _baseUrl!);
      await api.updateColorByNumberLegend(
        token: _token!,
        activityId: widget.activityId,
        legend: _legend,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Legend saved ✅")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imageUrl = _activity?["imageUrl"]?.toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgWarmPink,
        title: Text(
          "Set Colors",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveLegend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgWarmPink,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                "Save",
                style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgWarmPink.withOpacity(0.12), Colors.white],
          ),
        ),
        child: Column(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, color: AppColors.bgWarmPink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tap any number to choose its color.",
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgWarmPink.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bgWarmPink.withOpacity(0.28)),
                      ),
                      child: Text(
                        "Regions: $_regionsCount",
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: _legend.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (_, index) {
                  final item = _legend[index];
                  final number = item["number"];
                  final colorHex = item["colorHex"].toString();
                  final color = _hexToColor(colorHex);

                  return InkWell(
                    onTap: () => _pickColor(index),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$number",
                              style: GoogleFonts.robotoSlab(
                                fontWeight: FontWeight.w900,
                                color: (color.computeLuminance() < 0.45)
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
