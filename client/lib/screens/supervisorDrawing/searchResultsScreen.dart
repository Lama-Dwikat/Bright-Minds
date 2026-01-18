import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import 'colorByNumberLegendScreen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String type;
  final String backendUrl;
  final int? regionsCount;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.type,
    required this.backendUrl,
    this.regionsCount,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool isLoading = false;
  List<dynamic> images = [];

  bool isAdding = false;
  String? addingUrl;

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  bool get _isColoring => widget.type == "coloring";
  bool get _isColorByNumber => widget.type == "colorByNumber";

  // ✅ nicer web width
  double _maxWidth(double w) {
    if (!kIsWeb) return w;
    if (w >= 1400) return 1100;
    if (w >= 1100) return 980;
    if (w >= 900) return 900;
    return w;
  }

  // ✅ responsive columns for web grid
  int _gridCols(double w) {
    if (!kIsWeb) return 2; // mobile default
    if (w >= 1300) return 4;
    if (w >= 980) return 3;
    if (w >= 700) return 2;
    return 1;
  }

  Future<void> addImage(String imageUrl) async {
    final token = await _token();
    if (token == null) return;

    setState(() {
      isAdding = true;
      addingUrl = imageUrl;
    });

    try {
      final url = Uri.parse("${widget.backendUrl}/api/drawing/addFromExternal");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "imageUrl": imageUrl,
          "title": "${widget.query} ${widget.type}",
          "type": widget.type,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Drawing added successfully ✅")),
        );

        setState(() {
          images = images.map((it) {
            if (it is Map &&
                (it["largeImageURL"] == imageUrl ||
                    it["previewURL"] == imageUrl)) {
              return {...it, "_alreadyAdded": true};
            }
            return it;
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add drawing (${response.statusCode}) ❌"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAdding = false;
          addingUrl = null;
        });
      }
    }
  }

  Future<void> _searchOrGenerate() async {
    setState(() {
      isLoading = true;
      images = [];
    });

    final token = await _token();
    if (token == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      if (widget.type == "tracing") {
        await _generateTracing(token);
      } else if (widget.type == "surpriseColor") {
        await _generateCopy(token);
      } else if (widget.type == "colorByNumber") {
        await _generateColorByNumber(token);
      } else {
        await _searchExternal(token);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _searchExternal(String token) async {
    final url = Uri.parse(
      "${widget.backendUrl}/api/drawing/searchExternal?q=${Uri.encodeComponent(widget.query)}&type=${widget.type}",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        images = (decoded is List) ? decoded : [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateTracing(String token) async {
    final url = Uri.parse("${widget.backendUrl}/api/drawing/generateTracing");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"q": widget.query}),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);
      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tracing generated & added ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateCopy(String token) async {
    final url = Uri.parse("${widget.backendUrl}/api/drawing/generateCopy");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"q": widget.query}),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);
      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reference generated & added ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateColorByNumber(String token) async {
    final url =
        Uri.parse("${widget.backendUrl}/api/drawing/generateColorByNumber");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "q": widget.query,
        "regionsCount": widget.regionsCount,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);

      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
            "_activityId": activity["_id"] ?? activity["id"],
            "_maskUrl": activity["maskUrl"],
            "_regionsCount": activity["regionsCount"],
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Color-by-number generated ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchOrGenerate();
  }

  void _openLegend(String activityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColorByNumberLegendScreen(activityId: activityId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = "${widget.type} • ${widget.query}";

    return Scaffold(
      backgroundColor: AppColors.creamYellow,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxWidth(c.maxWidth)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBody(c.maxWidth),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(double width) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (images.isEmpty) {
      return Center(
        child: Text(
          "No results",
          style: GoogleFonts.robotoSlab(fontSize: 16),
        ),
      );
    }

    // ✅ single result types stay “big centered”
    if (!_isColoring) {
      final first = images.first;
      final map = (first is Map) ? first : <String, dynamic>{};

      final preview = (map["previewURL"] ?? "").toString();
      final large = (map["largeImageURL"] ?? preview).toString();
      final alreadyAdded = map["_alreadyAdded"] == true;

      final activityId = (map["_activityId"] ?? "").toString();

      return _SingleBigResult(
        imageUrl: preview,
        buttonText: alreadyAdded ? "Added" : "Add",
        isBusy: isAdding && (addingUrl == large || addingUrl == preview),
        onPressed: alreadyAdded
            ? null
            : () {
                final target = large.isNotEmpty ? large : preview;
                if (target.isNotEmpty) addImage(target);
              },
        showLegendButton:
            _isColorByNumber && alreadyAdded && activityId.isNotEmpty,
        onLegendPressed:
            (_isColorByNumber && alreadyAdded && activityId.isNotEmpty)
                ? () => _openLegend(activityId)
                : null,
      );
    }

    // ✅ responsive grid for coloring results
    final cols = _gridCols(width);
    final ratio = cols == 1 ? 1.35 : 0.86;

    return GridView.builder(
      itemCount: images.length,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: ratio,
      ),
      itemBuilder: (context, index) {
        final img = images[index];
        final map = (img is Map) ? img : <String, dynamic>{};

        final alreadyAdded = map["_alreadyAdded"] == true;
        final preview = (map["previewURL"] ?? "").toString();
        final large = (map["largeImageURL"] ?? "").toString();

        final busy = isAdding && (addingUrl == large || addingUrl == preview);

        return _GridImageCard(
          imageUrl: preview,
          buttonText: alreadyAdded ? "Added" : "Add",
          isBusy: busy,
          onPressed: alreadyAdded || large.isEmpty ? null : () => addImage(large),
        );
      },
    );
  }
}

class _SingleBigResult extends StatelessWidget {
  final String imageUrl;
  final String buttonText;
  final bool isBusy;
  final VoidCallback? onPressed;

  final bool showLegendButton;
  final VoidCallback? onLegendPressed;

  const _SingleBigResult({
    required this.imageUrl,
    required this.buttonText,
    required this.isBusy,
    required this.onPressed,
    required this.showLegendButton,
    required this.onLegendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 36),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softSunYellow,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isBusy ? null : onPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        buttonText,
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (showLegendButton) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLegendPressed,
                    icon: const Icon(Icons.palette),
                    label: Text(
                      "Set Colors (Legend)",
                      style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softSunYellow,
                      side: BorderSide(
                        color: AppColors.softSunYellow.withOpacity(0.6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridImageCard extends StatelessWidget {
  final String imageUrl;
  final String buttonText;
  final bool isBusy;
  final VoidCallback? onPressed;

  const _GridImageCard({
    required this.imageUrl,
    required this.buttonText,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: isBusy ? null : onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onPressed == null
                      ? Colors.grey.shade200
                      : AppColors.softSunYellow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBusy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        onPressed == null ? Icons.check : Icons.add,
                        color: onPressed == null ? Colors.black54 : Colors.white,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w900,
                        color: onPressed == null ? Colors.black54 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}










/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bright_minds/theme/colors.dart';
import 'colorByNumberLegendScreen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String type;
  final String backendUrl;
  final int? regionsCount;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.type,
    required this.backendUrl,
    this.regionsCount,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool isLoading = false;
  List<dynamic> images = [];

  bool isAdding = false;
  String? addingUrl;

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  bool get _isColoring => widget.type == "coloring";
  bool get _isColorByNumber => widget.type == "colorByNumber";

  Future<void> addImage(String imageUrl) async {
    final token = await _token();
    if (token == null) return;

    setState(() {
      isAdding = true;
      addingUrl = imageUrl;
    });
String getBackendUrl() {
    if (kIsWeb)
      return "http://localhost:3000";
    return "http://10.0.2.2:3000"; // Android emulator
  }
    try {
      final url = Uri.parse("${widget.backendUrl}/api/drawing/addFromExternal");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "imageUrl": imageUrl,
          "title": "${widget.query} ${widget.type}",
          "type": widget.type,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Drawing added successfully ✅")),
        );

        setState(() {
          images = images.map((it) {
            if (it is Map &&
                (it["largeImageURL"] == imageUrl ||
                    it["previewURL"] == imageUrl)) {
              return {...it, "_alreadyAdded": true};
            }
            return it;
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to add drawing (${response.statusCode}) ❌",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAdding = false;
          addingUrl = null;
        });
      }
    }
  }

  Future<void> _searchOrGenerate() async {
    setState(() {
      isLoading = true;
      images = [];
    });

    final token = await _token();
    if (token == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      if (widget.type == "tracing") {
        await _generateTracing(token);
      } else if (widget.type == "surpriseColor") {
        await _generateCopy(token);
      } else if (widget.type == "colorByNumber") {
        await _generateColorByNumber(token);
      } else {
        await _searchExternal(token);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _searchExternal(String token) async {
    final url = Uri.parse(
      "${widget.backendUrl}/api/drawing/searchExternal?q=${Uri.encodeComponent(widget.query)}&type=${widget.type}",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        images = (decoded is List) ? decoded : [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateTracing(String token) async {
    final url = Uri.parse("${widget.backendUrl}/api/drawing/generateTracing");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"q": widget.query}),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);
      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tracing generated & added ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateCopy(String token) async {
    final url = Uri.parse("${widget.backendUrl}/api/drawing/generateCopy");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"q": widget.query}),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);
      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reference generated & added ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ❌")),
      );
    }
  }

  Future<void> _generateColorByNumber(String token) async {
    final url =
        Uri.parse("${widget.backendUrl}/api/drawing/generateColorByNumber");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "q": widget.query,
        "regionsCount": widget.regionsCount,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final activity = jsonDecode(response.body);

      setState(() {
        images = [
          {
            "previewURL": activity["imageUrl"],
            "largeImageURL": activity["imageUrl"],
            "_alreadyAdded": true,
            "_activityId": activity["_id"] ?? activity["id"],
            "_maskUrl": activity["maskUrl"],
            "_regionsCount": activity["regionsCount"],
          }
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Color-by-number generated ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode}) ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchOrGenerate();
  }

  void _openLegend(String activityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColorByNumberLegendScreen(activityId: activityId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = "${widget.type} • ${widget.query}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (images.isEmpty) {
      return Center(
        child: Text(
          "No results",
          style: GoogleFonts.robotoSlab(fontSize: 16),
        ),
      );
    }

    if (!_isColoring) {
      final first = images.first;
      final map = (first is Map) ? first : <String, dynamic>{};

      final preview = (map["previewURL"] ?? "").toString();
      final large = (map["largeImageURL"] ?? preview).toString();
      final alreadyAdded = map["_alreadyAdded"] == true;

      final activityId = (map["_activityId"] ?? "").toString();

      return _SingleBigResult(
        imageUrl: preview,
        buttonText: alreadyAdded ? "Added" : "Add",
        isBusy: isAdding && (addingUrl == large || addingUrl == preview),
        onPressed: alreadyAdded
            ? null
            : () {
                final target = large.isNotEmpty ? large : preview;
                if (target.isNotEmpty) addImage(target);
              },
        showLegendButton: _isColorByNumber && alreadyAdded && activityId.isNotEmpty,
        onLegendPressed: (_isColorByNumber && alreadyAdded && activityId.isNotEmpty)
            ? () => _openLegend(activityId)
            : null,
      );
    }

    return GridView.builder(
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final img = images[index];
        final map = (img is Map) ? img : <String, dynamic>{};

        final alreadyAdded = map["_alreadyAdded"] == true;
        final preview = (map["previewURL"] ?? "").toString();
        final large = (map["largeImageURL"] ?? "").toString();

        final busy = isAdding && (addingUrl == large || addingUrl == preview);

        return _GridImageCard(
          imageUrl: preview,
          buttonText: alreadyAdded ? "Added" : "Add",
          isBusy: busy,
          onPressed: alreadyAdded || large.isEmpty ? null : () => addImage(large),
        );
      },
    );
  }
}

class _SingleBigResult extends StatelessWidget {
  final String imageUrl;
  final String buttonText;
  final bool isBusy;
  final VoidCallback? onPressed;

  final bool showLegendButton;
  final VoidCallback? onLegendPressed;

  const _SingleBigResult({
    required this.imageUrl,
    required this.buttonText,
    required this.isBusy,
    required this.onPressed,
    required this.showLegendButton,
    required this.onLegendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.grey.shade100,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 36),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softSunYellow,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isBusy ? null : onPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.add, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      buttonText,
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showLegendButton) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLegendPressed,
                  icon: const Icon(Icons.palette),
                  label: Text(
                    "Set Colors (Legend)",
                    style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softSunYellow,
                    side: BorderSide(color: AppColors.softSunYellow.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

class _GridImageCard extends StatelessWidget {
  final String imageUrl;
  final String buttonText;
  final bool isBusy;
  final VoidCallback? onPressed;

  const _GridImageCard({
    required this.imageUrl,
    required this.buttonText,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: isBusy ? null : onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onPressed == null
                      ? Colors.grey.shade200
                      : AppColors.softSunYellow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBusy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        onPressed == null ? Icons.check : Icons.add,
                        color: onPressed == null
                            ? Colors.black54
                            : Colors.white,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w900,
                        color: onPressed == null
                            ? Colors.black54
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/