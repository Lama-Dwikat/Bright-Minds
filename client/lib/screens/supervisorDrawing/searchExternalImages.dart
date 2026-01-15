import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import 'package:bright_minds/theme/colors.dart';
import 'searchResultsScreen.dart';

class SearchExternalImagesScreen extends StatefulWidget {
  const SearchExternalImagesScreen({super.key});

  @override
  State<SearchExternalImagesScreen> createState() => _SearchExternalImagesScreenState();
}

class _SearchExternalImagesScreenState extends State<SearchExternalImagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String selectedType = "coloring";
  bool isLoading = false;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> _ageGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("ageGroup");
  }

  String _hintForType() {
    switch (selectedType) {
      case "tracing":
        return "Search (cat, apple, ...)";
      case "surpriseColor":
        return "Search (cat, apple, ...)";
      case "colorByNumber":
        return "Search (cat, apple, ...)";
      default:
        return "Search (apple, cat, house...)";
    }
  }

  String _titleForType(String t) {
    switch (t) {
      case "coloring":
        return "Coloring";
      case "tracing":
        return "Tracing (AI)";
      case "surpriseColor":
        return "Reference (AI)";
      case "colorByNumber":
        return "Color By Number";
      default:
        return t;
    }
  }

 Future<int?> _askRegionsCount() async {
  final age = await _ageGroup();
  final rules = (age == "5-8")
      ? const _RegionsRule(min: 6, max: 10)
      : (age == "9-12")
          ? const _RegionsRule(min: 10, max: 20)
          : const _RegionsRule(min: 6, max: 20);

  int value = rules.min;

  final result = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgWarmPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.grid_on_rounded,
                color: AppColors.bgWarmPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Regions Count",
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Choose number of regions",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgWarmPink.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.bgWarmPink.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          "$value",
                          style: GoogleFonts.robotoSlab(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.bgWarmPink,
                    inactiveTrackColor: AppColors.bgWarmPink.withOpacity(0.25),
                    thumbColor: AppColors.bgWarmPink,
                    overlayColor: AppColors.bgWarmPink.withOpacity(0.15),
                    trackHeight: 4.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: rules.min.toDouble(),
                    max: rules.max.toDouble(),
                    divisions: (rules.max - rules.min),
                    onChanged: (v) => setLocal(() => value = v.round()),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${rules.min}",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 12,
                        color: const Color.fromARGB(241, 0, 0, 0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${rules.max}",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 12,
                        color: const Color.fromARGB(233, 0, 0, 0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Allowed range: ${rules.min} – ${rules.max}",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 12,
                    color: const Color.fromARGB(213, 0, 0, 0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              "Cancel",
              style: GoogleFonts.robotoSlab(
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bgWarmPink,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, value),
            child: Text(
              "Continue",
              style: GoogleFonts.robotoSlab(
                fontWeight: FontWeight.w900,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ],
      );
    },
  );

  return result;
}


  Future<void> _goSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    int? regionsCount;
    if (selectedType == "colorByNumber") {
      regionsCount = await _askRegionsCount();
      if (regionsCount == null) return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: q,
          type: selectedType,
          backendUrl: getBackendUrl(),
          regionsCount: regionsCount,
        ),
      ),
    );
  }

  Future<void> uploadFromDevice() async {
    final token = await _token();
    if (token == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;

    final title = _searchController.text.trim().isEmpty
        ? "Uploaded $selectedType"
        : "${_searchController.text.trim()} $selectedType";

    final url = Uri.parse("${getBackendUrl()}/api/drawing/upload");

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = title;
      request.fields["type"] = selectedType;

      final ext = p.extension(picked.name).toLowerCase();

      String mime = "image/jpeg";
      if (ext == ".png") mime = "image/png";
      if (ext == ".webp") mime = "image/webp";

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            bytes,
            filename: picked.name,
            contentType: MediaType.parse(mime),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            picked.path,
            filename: picked.name,
            contentType: MediaType.parse(mime),
          ),
        );
      }

      final streamed = await request.send();
      final respBody = await streamed.stream.bytesToString();

      if (!mounted) return;

      if (streamed.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded successfully ✅")),
        );
      } else {
        debugPrint("UPLOAD FAILED: ${streamed.statusCode} BODY: $respBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed (${streamed.statusCode}) ❌")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      _TypeItem(
        value: "coloring",
        label: "Coloring",
        assetPath: "assets/images/d1.png",
        icon: Icons.brush,
      ),
      _TypeItem(
        value: "tracing",
        label: "Tracing (AI)",
        assetPath: "assets/images/d2.png",
        icon: Icons.gesture,
      ),
      _TypeItem(
        value: "surpriseColor",
        label: "Reference (AI)",
        assetPath: "assets/images/d3.png",
        icon: Icons.image_search,
      ),
      _TypeItem(
        value: "colorByNumber",
        label: "Color By Number",
        assetPath: "assets/images/d4.png",
        icon: Icons.grid_on,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Drawing Search",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgWarmPink.withOpacity(0.18),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),
                Expanded(child: _buildTypeGrid(types)),
                const SizedBox(height: 12),
                _buildHintCard(),
                const SizedBox(height: 12),
                _buildMainActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 5),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black45, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _goSearch(),
              textInputAction: TextInputAction.search,
              style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: _hintForType(),
                hintStyle: GoogleFonts.robotoSlab(color: Colors.black45, fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: isLoading ? null : () => _searchController.clear(),
            icon: const Icon(Icons.close, color: Colors.black45),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

 Widget _buildTypeGrid(List<_TypeItem> types) {
  return GridView.builder(
    itemCount: types.length,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.92,
    ),
    itemBuilder: (_, i) {
      final item = types[i];
      final selected = item.value == selectedType;

      return _TypeCard(
        item: item,
        selected: selected,
        onTap: () => setState(() => selectedType = item.value),
      );
    },
  );
}


  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgWarmPink.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tips_and_updates, color: AppColors.bgWarmPink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Selected: ${_titleForType(selectedType)}\nType a word then press Search.",
              style: GoogleFonts.robotoSlab(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _goSearch,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.search),
            label: Text(
              "Search",
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bgWarmPink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isLoading ? null : uploadFromDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.bgWarmPink,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: AppColors.bgWarmPink.withOpacity(0.6)),
          ),
          child: const Icon(Icons.upload),
        ),
      ],
    );
  }
}

class _RegionsRule {
  final int min;
  final int max;
  const _RegionsRule({required this.min, required this.max});
}

class _TypeItem {
  final String value;
  final String label;
  final String assetPath;
  final IconData icon;

  _TypeItem({
    required this.value,
    required this.label,
    required this.assetPath,
    required this.icon,
  });
}

class _TypeCard extends StatelessWidget {
  final _TypeItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            elevation: selected ? 5 : 2,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 1.60,
                        child: Image.asset(
                          item.assetPath,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: Colors.white,
                              child: Center(
                                child: Icon(item.icon, size: 56, color: Colors.black45),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.bgWarmPink : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          selected ? Icons.check : Icons.circle_outlined,
                          color: selected ? AppColors.bgWarmPink : Colors.black38,
                          size: 18,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Container(height: 4, color: AppColors.bgWarmPink),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
