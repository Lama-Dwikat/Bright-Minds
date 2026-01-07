import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class SearchExternalImagesScreen extends StatefulWidget {
  const SearchExternalImagesScreen({super.key});

  @override
  State<SearchExternalImagesScreen> createState() =>
      _SearchExternalImagesScreenState();
}

class _SearchExternalImagesScreenState
    extends State<SearchExternalImagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String selectedType = "coloring";
  bool isLoading = false;
  List images = [];

  // ================= BACKEND URL =================
  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

// ================= ADD IMAGE =================
Future<void> addImage(String imageUrl) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");

  final url = Uri.parse(
    "${getBackendUrl()}/api/drawing/addFromExternal",
  );

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "imageUrl": imageUrl,
      "title": "${_searchController.text} ${selectedType}",
      "type": selectedType,
    }),
  );

  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Drawing added successfully ✅"),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to add drawing (${response.statusCode}) ❌"),
      ),
    );
  }
}

  // ================= SEARCH API =================
  Future<void> searchImages() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      images = [];
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse(
      "${getBackendUrl()}/api/drawing/searchExternal"
      "?q=${_searchController.text}&type=$selectedType",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        images = jsonDecode(response.body);
      });
    } else {
      debugPrint("Search failed: ${response.statusCode}");
    }

    setState(() {
      isLoading = false;
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search Drawing Images",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH BAR =================
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search (apple, cat, house...)",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: searchImages,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bgWarmPink,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          child: const Icon(Icons.search),
        ),
      ],
    );
  }

  // ================= TYPE FILTER =================
  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _typeChip("coloring", "Coloring"),
        _typeChip("tracing", "Tracing"),
        _typeChip("colorByNumber", "Color by Number"),
      ],
    );
  }

  Widget _typeChip(String value, String label) {
    final isSelected = selectedType == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedType = value;
        });
      },
      selectedColor: AppColors.bgWarmPink,
    );
  }

  // ================= RESULTS GRID =================
  Widget _buildResults() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (images.isEmpty) {
      return Center(
        child: Text(
          "No images yet",
          style: GoogleFonts.robotoSlab(fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
  final img = images[index];

  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          img["previewURL"],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),

      // ADD BUTTON
      Positioned(
        bottom: 6,
        right: 6,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bgWarmPink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () {
            addImage(img["largeImageURL"]);
          },
          child: const Text(
            "Add",
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
    ],
  );
},

    );
  }
}
