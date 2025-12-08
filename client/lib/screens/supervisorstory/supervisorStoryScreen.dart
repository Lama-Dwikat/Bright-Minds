import 'package:flutter/material.dart';
import 'package:bright_minds/screens/SupervisorStory/storyService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorStoryScreen extends StatefulWidget {
  @override
  State<SupervisorStoryScreen> createState() => _SupervisorStoryScreenState();
}

class _SupervisorStoryScreenState extends State<SupervisorStoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String selectedAgeGroup = "9-12";
  final ageGroups = ["3-5", "6-8", "9-12"];

  String? token;

  bool loading = false;
  List<dynamic> results = [];

  Color peach = const Color(0xffFFD8C2);
  Color peachDark = const Color(0xffE78F81);
  Color peachSoft = const Color(0xffFFEFE6);

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token") ?? "";
    });
  }

  Future<void> search() async {
    if (_searchCtrl.text.trim().isEmpty || token!.isEmpty) return;

    setState(() => loading = true);

    try {
      final data = await StoryService.searchStories(
        _searchCtrl.text.trim(),
        token!,
      );
      setState(() => results = data);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Search failed")));
    }

    setState(() => loading = false);
  }

  Future<void> handleImportStory(dynamic id, String source) async {
    if (token == null || token!.isEmpty) return;

    final result = await StoryService.importStory(
      id.toString(),
      selectedAgeGroup,
      source,
      token!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: peachDark,
        content: Text(result["message"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return Scaffold(
        backgroundColor: peachSoft,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: peachSoft,
      appBar: AppBar(
        title: Text("📚 Supervisor Story Library"),
        backgroundColor: peachDark,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔍 Search input
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: peachDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: "Search children stories...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: peachDark),
                        onPressed: token!.isEmpty ? null : search,
                      )
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // 🔽 selector
                Row(
                  children: [
                    Text("Age Group:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    DropdownButton(
                      value: selectedAgeGroup,
                      items: ageGroups.map((age) {
                        return DropdownMenuItem(
                          value: age,
                          child: Text(age),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedAgeGroup = value!),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // 🧺 Results list — NO overflow
                loading
                    ? Center(child: CircularProgressIndicator())
                    : results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                "🔍 No stories found.",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              var book = results[index];

                              return Card(
                                color: peach,
                                elevation: 2,
                                child: ListTile(
                                  leading: book["image"] != null
                                      ? Image.network(book["image"], width: 50)
                                      : Image.asset("assets/images/story2.png",
                                          width: 50),

                                  title: Text(book["title"], maxLines: 1),
                                  subtitle: Text(
                                    book["summary"] ?? "No description",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("${book["source"]}",
                                          style: TextStyle(fontSize: 10)),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: peachDark,
                                        ),
                                        onPressed: () => handleImportStory(
                                          book["externalId"],
                                          book["source"],
                                        ),
                                        child: Text("Import"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
