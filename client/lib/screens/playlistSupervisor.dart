


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class SupervisorPlaylistScreen extends StatefulWidget {
  const SupervisorPlaylistScreen({super.key});

  @override
  State<SupervisorPlaylistScreen> createState() =>
      _SupervisorPlaylistScreenState();
}

class _SupervisorPlaylistScreenState extends State<SupervisorPlaylistScreen> {
  List<dynamic> allVideos = [];
  List<dynamic> playlists = [];
  bool loading = true;
  String userId = "";
    dynamic currentVideo;
  YoutubePlayerController? ytController;

  // for playlist creation/editing
  Set<String> selectedVideoIds = {};
  bool playlistLoading = false;
  List<String> ageGroups = ["5-8", "9-12"];
    String selectedAgeGroup = "5-8";
  


  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await loadSupervisorVideos();
    await loadPlaylists();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }



  // -------------------------
  // Load Supervisor Videos
  // -------------------------
  Future<void> loadSupervisorVideos() async {
    setState(() => loading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) return;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getPublishSupervisorVideos/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          allVideos = jsonDecode(response.body);
        });
      } else {
        print("Failed to load videos: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Error loading videos: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // -------------------------
  // Playlist APIs
  // -------------------------
  Future<void> loadPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/playlists/getPlaylistBySupervisor/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          playlists = jsonDecode(response.body);
        });
      } else {
        print("Failed to load playlists: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ loadPlaylists error: $e");
    }
  }

  Future<void> createPlaylist({
    required String title,
    String? description,
    required String category,
     required String ageGroup,   
    required List<String> videoIds,
  }) async {
    setState(() => playlistLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${getBackendUrl()}/api/playlists/createPlaylist"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": description ?? "",
          "category": category,
          "videos": videoIds,
          "isPublished": false,
          "createdBy": userId,
          "ageGroup": selectedAgeGroup,  
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadPlaylists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Playlist created")));
        }
      } else {
        print("Create playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ createPlaylist error: $e");
    } finally {
      setState(() => playlistLoading = false);
    }
  }

  Future<void> updatePlaylist(
      String playlistId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/updatePlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Playlist updated")));
        }
      } else {
        print("Update playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ updatePlaylist error: $e");
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      final response = await http.delete(
        Uri.parse("${getBackendUrl()}/api/playlists/deletePlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Playlist deleted")));
        }
      } else {
        print("Delete playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ deletePlaylist error: $e");
    }
  }

  Future<void> publishPlaylist(String playlistId, bool publish) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/publishPlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isPublished": publish}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(publish ? "Playlist published" : "Playlist unpublished")));
        }
      } else {
        print("Publish playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ publishPlaylist error: $e");
    }
  }

  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/addVideo/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
      } else {
        print("addVideoToPlaylist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ addVideoToPlaylist error: $e");
    }
  }

  Future<void> deleteVideoFromPlaylist(String playlistId, String videoId) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/deleteVideo/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
      } else {
        print("removeVideoFromPlaylist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ removeVideoFromPlaylist error: $e");
    }
  }

  // -------------------------
  // UI Helpers
  // -------------------------
  void showCreatePlaylistDialog() {
    
    final titleController = TextEditingController();
    final descController = TextEditingController();
    List<String> categories = [
      "General",
      "English",
      "Arabic",
      "Math",
      "Science",
      "Animation",
      "Art",
      "Music",
      "Coding/Technology"
    ];
    String selectedCategory = categories.first;
    selectedVideoIds.clear();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Create Playlist"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title")),
                  TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description")),
                  DropdownButtonFormField(
                    value: selectedCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedCategory = v.toString()),
                  ),
                  DropdownButtonFormField(
                               value: selectedAgeGroup,
                       decoration: const InputDecoration(labelText: "Age Group"),
                      items: ageGroups
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedAgeGroup = v.toString()),
                      ),

                  const SizedBox(height: 12),
                  const Text("Select videos to include:"),
                  SizedBox(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: allVideos.length,
                      itemBuilder: (_, i) {
                        final v = allVideos[i];
                        final id = v["_id"].toString();
                        final title = v["title"] ?? "";
                        return CheckboxListTile(
                          value: selectedVideoIds.contains(id),
                          onChanged: (val) => setStateDialog(() {
                            if (val == true)
                              selectedVideoIds.add(id);
                            else
                              selectedVideoIds.remove(id);
                          }),
                          title: Text(title),
                          secondary: v["thumbnailUrl"] != null
                              ? Image.network(v["thumbnailUrl"], width: 40, height: 40, fit: BoxFit.cover)
                              : const SizedBox(width: 40, height: 40),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: selectedVideoIds.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await createPlaylist(
                          title: titleController.text.isEmpty
                              ? "New Playlist"
                              : titleController.text,
                          description: descController.text,
                          category: selectedCategory,
                           ageGroup: selectedAgeGroup,                    
                          videoIds: selectedVideoIds.toList(),
                        );
                        setState(() {});
                      },
                child: playlistLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Create"),
              )
            ],
          );
        });
      },
    );
  }

  // EDIT playlist dialog (full editing: title, desc, category, videos)
  void showEditPlaylistDialog(Map<String, dynamic> playlist) {
    final titleController = TextEditingController(text: playlist["title"]);
    final descController = TextEditingController(text: playlist["description"]);
    List<String> categories = [
      "General",
      "English",
      "Arabic",
      "Math",
      "Science",
      "Animation",
      "Art",
      "Music",
      "Coding/Technology"
    ];
    String selectedCategory = playlist["category"] ?? categories.first;

    // convert playlist videos to set of ids (handles both String _id or embedded objects)
    Set<String> existingVideos = Set<String>.from(
      (playlist["videos"] ?? []).map((v) => v is String ? v : (v["_id"]?.toString() ?? "")),
    );

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Playlist"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                    const SizedBox(height: 8),

                    // Category dropdown
                    DropdownButtonFormField(
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setStateDialog(() => selectedCategory = v.toString()),
                    ),

                    const SizedBox(height: 12),
                    const Text("Videos in this playlist:"),
                    SizedBox(
                      height: 220,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: allVideos.length,
                        itemBuilder: (_, i) {
                          final v = allVideos[i];
                          final id = v["_id"].toString();
                          final isIncluded = existingVideos.contains(id);

                          return CheckboxListTile(
                            value: isIncluded,
                            title: Text(v["title"] ?? ""),
                            secondary: v["thumbnailUrl"] != null
                                ? Image.network(v["thumbnailUrl"], width: 40, height: 40, fit: BoxFit.cover)
                                : const SizedBox(width: 40, height: 40),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  existingVideos.add(id);
                                } else {
                                  existingVideos.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await updatePlaylist(playlist["_id"], {
                      "title": titleController.text,
                      "description": descController.text,
                      "category": selectedCategory,
                      "videos": existingVideos.toList(),
                    });
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // VIEW playlist details (readonly list of videos + remove per-video)
  void showPlaylistDetailDialog(Map<String, dynamic> playlist) {
    final currentVideos = List<String>.from(
        (playlist["videos"] ?? []).map((v) => v is String ? v : v["_id"].toString()));

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Playlist: ${playlist["title"]}"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playlist["description"] != null && playlist["description"].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(playlist["description"]),
                    ),
                  const SizedBox(height: 6),
                  Text("Videos in playlist:"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: currentVideos.length,
                      itemBuilder: (_, index) {
                        final vidId = currentVideos[index];
                        final v = allVideos.firstWhere((el) => el["_id"].toString() == vidId, orElse: () => null);
                        final title = v != null ? (v["title"] ?? "Unknown") : "Unknown video (deleted)";
                        return ListTile(
                          leading: v != null && v["thumbnailUrl"] != null
                              ? Image.network(v["thumbnailUrl"], width: 56, height: 40, fit: BoxFit.cover)
                              : const SizedBox(width: 56, height: 40),
                          title: Text(title),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppColors.bgBlushRoseDark),
                            onPressed: () async {
                              await deleteVideoFromPlaylist(playlist["_id"], vidId);
                              setStateDialog(() {
                                currentVideos.removeAt(index);
                              });
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await deletePlaylist(playlist["_id"]);
                },
                child: const Text("Delete", style: TextStyle(color: AppColors.bgBlushRoseDark)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showEditPlaylistDialog(playlist);
                },
                child: const Text("Edit"),
              ),
            ],
          );
        });
      },
    );
  }



  // Confirm delete playlist (optional helper)
  Future<void> _confirmDeletePlaylist(String playlistId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete playlist"),
        content: const Text("Are you sure you want to delete this playlist? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgBlushRoseVeryDark),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (ok == true) await deletePlaylist(playlistId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading && playlists.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : playlists.isEmpty
              ? const Center(child: Text("No playlists yet", style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (_, i) {
                    final p = playlists[i];
                    final pVideos = (p["videos"] ?? []);
                    String? thumb;
                    if (pVideos.isNotEmpty) {
                      final first = pVideos[0];
                      if (first is String) {
                        final v = allVideos.firstWhere((el) => el["_id"].toString() == first, orElse: () => null);
                        thumb = v != null ? v["thumbnailUrl"] : null;
                      } else if (first is Map && first["thumbnailUrl"] != null) {
                        thumb = first["thumbnailUrl"];
                      }
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p["title"] ?? "Untitled", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${p["category"] ?? "No category"} • ${pVideos.length} videos"),
                            const SizedBox(height: 8),
                            pVideos.isNotEmpty
                                ? SizedBox(
                                    height: 85,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: pVideos.length,
                                      itemBuilder: (_, j) {
                                        final idStr = pVideos[j] is String ? pVideos[j] : pVideos[j]["_id"].toString();
                                        final v = allVideos.firstWhere((el) => el["_id"].toString() == idStr, orElse: () => null);
                                        final thumbLocal = v?["thumbnailUrl"];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: thumbLocal != null
                                              ? Image.network(thumbLocal, width: 100, height: 100, fit: BoxFit.cover)
                                              : Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.videocam),
                                                ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: Text("No videos in playlist")),
                                  ),
                            const SizedBox(height: 8),
                            // Footer with buttons (Layout B)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Publish toggle
                                IconButton(
                                  icon: Icon(
                                    p["isPublished"] == true ? Icons.check_circle : Icons.check_circle_outline,
                                    color: p["isPublished"] == true ? Colors.green : AppColors.bgWarmPinkVeryDark,
                                  ),
                                  onPressed: () => publishPlaylist(p["_id"], !(p["isPublished"] == true)),
                                  tooltip: p["isPublished"] == true ? "Unpublish" : "Publish",
                                ),

                                // ADD VIDEO button (separate, as requested - Layout B)
                                

                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => showEditPlaylistDialog(p),
                                  tooltip: "Edit playlist",
                                ),

                                // Delete (with confirmation)
                                IconButton(
                                  icon: const Icon(Icons.delete, color:AppColors.bgBlushRoseVeryDark),
                                  onPressed: () => _confirmDeletePlaylist(p["_id"]),
                                  tooltip: "Delete playlist",
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreatePlaylistDialog,
        label: const Text("Create Playlist"),
        icon: const Icon(Icons.playlist_add),
          backgroundColor: AppColors.bgBlushRose, // for example
      ),
    );
  }
}
