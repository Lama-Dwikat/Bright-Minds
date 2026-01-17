import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import '../../services/drawingApi.dart';

class _StrokePoint {
  final Offset p; // in widget coordinates
  final Color color;
  final double radius;
  _StrokePoint(this.p, this.color, this.radius);
}

class ColorByNumberPlayScreen extends StatefulWidget {
  final String activityId;
  const ColorByNumberPlayScreen({super.key, required this.activityId});

  @override
  State<ColorByNumberPlayScreen> createState() => _ColorByNumberPlayScreenState();
}

class _ColorByNumberPlayScreenState extends State<ColorByNumberPlayScreen> {
  bool _loading = true;
  bool _saving = false;

  String? _token;
  String? _baseUrl;

  Map<String, dynamic>? _activity;

  String _imageUrl = "";
  int _regionsCount = 0;
  List<Map<String, dynamic>> _legend = [];

  ui.Image? _baseImg;

  int? _selectedNumber;
  Color _selectedColor = const Color(0xFFEF4444);

  double _brushRadius = 10; // feels like canvas
  final List<_StrokePoint> _strokes = [];

  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------- LOAD ----------------

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

      _imageUrl = (activity["imageUrl"] ?? "").toString();

      final regionsCountRaw = activity["regionsCount"] ?? 0;
      _regionsCount = regionsCountRaw is int
          ? regionsCountRaw
          : int.tryParse("$regionsCountRaw") ?? 0;

      // legend
      final legendRaw = (activity["legend"] ?? []) as List;
      _legend = [];

      if (legendRaw.isEmpty) {
        for (int i = 0; i < _regionsCount; i++) {
          _legend.add({"number": i + 1, "colorHex": "#EF4444"});
        }
      } else {
        for (final e in legendRaw) {
          _legend.add({
            "number": int.tryParse("${e["number"]}") ?? 0,
            "colorHex": (e["colorHex"] ?? "#EF4444").toString(),
          });
        }
        _legend.sort((a, b) => (a["number"] as int).compareTo(b["number"] as int));
      }

      if (_legend.isNotEmpty) {
        _selectedNumber = int.tryParse("${_legend.first["number"]}") ?? 1;
        _selectedColor = _hexToColor(_legend.first["colorHex"].toString());
      }

      // load base image
      if (_imageUrl.isNotEmpty) {
        _baseImg = await _loadUiImage(NetworkImage(_imageUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ui.Image> _loadUiImage(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener((info, _) {
      completer.complete(info.image);
      stream.removeListener(listener);
    }, onError: (e, _) {
      completer.completeError(e);
      stream.removeListener(listener);
    });

    stream.addListener(listener);
    return completer.future;
  }

  // ---------------- HELPERS ----------------

  Color _hexToColor(String hex) {
    final h = hex.replaceAll("#", "").toUpperCase();
    final safe = h.length == 6 ? h : "EF4444";
    return Color(int.parse("FF$safe", radix: 16));
  }

  String _colorToHex(Color c) {
    final hex = c.value.toRadixString(16).padLeft(8, '0');
    return "#${hex.substring(2).toUpperCase()}";
  }

  void _selectLegend(int number) {
    final item = _legend.firstWhere(
      (e) => int.tryParse("${e["number"]}") == number,
      orElse: () => {"number": number, "colorHex": "#EF4444"},
    );

    setState(() {
      _selectedNumber = number;
      _selectedColor = _hexToColor(item["colorHex"].toString());
    });
  }

  // IMPORTANT: only paint inside the displayed image rect
  Rect _imageDstRect(Size size) {
    final img = _baseImg!;
    final srcSize = Size(img.width.toDouble(), img.height.toDouble());
    final fit = applyBoxFit(BoxFit.contain, srcSize, size);
    final dstSize = fit.destination;
    final dx = (size.width - dstSize.width) / 2;
    final dy = (size.height - dstSize.height) / 2;
    return Rect.fromLTWH(dx, dy, dstSize.width, dstSize.height);
  }

  void _addPoint(Offset localPos, Size paintSize) {
    if (_baseImg == null) return;

    final dst = _imageDstRect(paintSize);
    if (!dst.contains(localPos)) return;

    setState(() {
      _strokes.add(_StrokePoint(localPos, _selectedColor, _brushRadius));
    });
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  // ---------------- SAVE & SEND ----------------

 Future<void> _saveAndSend() async {
  if (_token == null || _baseUrl == null) return;
  if (_saving) return;

  setState(() => _saving = true);

  try {
    final ro = _paintKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) throw "Render boundary missing";

    final img = await ro.toImage(pixelRatio: 2.0);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw "PNG encode failed";

    final pngBytes = bytes.buffer.asUint8List();

    // ✅ نحول الصورة Base64
    final b64 = base64Encode(pngBytes);

    // ✅ نبعثها للباك: save + submit + notify supervisor
    final url = Uri.parse("$_baseUrl/api/drawing/submitImage");

    final resp = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        "activityId": widget.activityId,
        "drawingImage": b64, // أو: "data:image/png;base64,$b64"
      }),
    );

    if (resp.statusCode != 201) {
      throw "Submit failed: ${resp.statusCode} ${resp.body}";
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved & Sent ✅")),
    );
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Save error: $e")),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmHoneyYellow,
        title: Text(
          "Color by Number",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: "Clear",
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveAndSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmHoneyYellow,
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
                  : const Icon(Icons.send),
              label: Text(
                "Save & Send",
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
            colors: [AppColors.warmHoneyYellow.withOpacity(0.10), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            _buildCanvas(),
            const SizedBox(height: 12),
            _hintCard(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Legend",
                  style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  "${_legend.length} colors",
                  style: GoogleFonts.robotoSlab(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _legendGrid(),
            const SizedBox(height: 10),
            _brushSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    if (_baseImg == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: Text(
              "Image not available",
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _paintKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: _baseImg!.width / _baseImg!.height,
          child: LayoutBuilder(
            builder: (ctx, c) {
              final size = Size(c.maxWidth, c.maxHeight);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _addPoint(d.localPosition, size),
                onPanUpdate: (d) => _addPoint(d.localPosition, size),
                child: CustomPaint(
                  painter: _CanvasPainter(
                    base: _baseImg!,
                    strokes: _strokes,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hintCard() {
    final n = _selectedNumber ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.brush, color: AppColors.warmHoneyYellow),
          const SizedBox(width: 10),
         
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warmHoneyYellow.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warmHoneyYellow.withOpacity(0.28)),
            ),
            child: Text(
              "Selected: $n",
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _legend.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) {
        final item = _legend[i];
        final number = int.tryParse("${item["number"]}") ?? (i + 1);
        final color = _hexToColor(item["colorHex"].toString());
        final selected = number == _selectedNumber;

        final textColor = (color.computeLuminance() < 0.45) ? Colors.white : Colors.black;

        return InkWell(
          onTap: () => _selectLegend(number),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? Colors.black : Colors.black12, width: selected ? 1.6 : 1),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$number",
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
               
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brushSlider() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Text("Brush", style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: _brushRadius,
              min: 4,
              max: 28,
              divisions: 24,
              onChanged: (v) => setState(() => _brushRadius = v),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final ui.Image base;
  final List<_StrokePoint> strokes;

  _CanvasPainter({required this.base, required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble());
    final fit = applyBoxFit(BoxFit.contain, src.size, size);

    final dstSize = fit.destination;
    final dx = (size.width - dstSize.width) / 2;
    final dy = (size.height - dstSize.height) / 2;
    final dst = Rect.fromLTWH(dx, dy, dstSize.width, dstSize.height);

    // draw base image
    canvas.drawImageRect(base, src, dst, Paint());

    // clip strokes to image area
    canvas.save();
    canvas.clipRect(dst);

    // draw strokes (canvas feel)
    for (final s in strokes) {
      final p = s.p;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawCircle(p, s.radius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.base != base || oldDelegate.strokes.length != strokes.length;
  }
}
