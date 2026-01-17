
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class SupervisorWeeklyPlannerScreen extends StatefulWidget {
  const SupervisorWeeklyPlannerScreen({super.key});

  @override
  State<SupervisorWeeklyPlannerScreen> createState() =>
      _SupervisorWeeklyPlannerScreenState();
}

class _SupervisorWeeklyPlannerScreenState
    extends State<SupervisorWeeklyPlannerScreen> with TickerProviderStateMixin {
  String? _token;
  String? _supervisorId;

  bool _loading = true;
  bool _loadingTemplates = false;
  bool _saving = false;
  bool _randoming = false;

  // Week start must be Saturday
  DateTime _weekStart = _startOfWeekSaturday(DateTime.now());

  // 7 slots (Sat..Fri)
  final List<Map<String, dynamic>?> _weekSlots = List.filled(7, null);

  // templates from backend
  List<Map<String, dynamic>> _templates = [];
  String _search = "";

  // categories tabs
  final List<String> _categories = const [
    "All",
    "religious",
    "reading",
    "health",
    "sport",
    "behavior",
    "art",
    "nature",
  ];

  late TabController _tabController;

  // kids for assignment
  bool _loadingKids = false;
  List<Map<String, dynamic>> _kids = [];
  final Set<String> _selectedKidIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }

    final decoded = JwtDecoder.decode(_token!);
    _supervisorId = decoded["id"]?.toString();

    await Future.wait([
      _fetchTemplates(),
      _fetchKidsForSupervisor(),
    ]);

    setState(() => _loading = false);
  }

  // -----------------------
  // Date helpers (Saturday start)
  // -----------------------
  static DateTime _startOfWeekSaturday(DateTime date) {
    // DateTime.weekday: Mon=1..Sun=7, Sat=6
    final d = DateTime(date.year, date.month, date.day);
    final int saturday = DateTime.saturday; // 6
    int diff = d.weekday - saturday;
    if (diff < 0) diff += 7;
    final start = d.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day); // 00:00
  }

  List<String> _dayLabels() => const [
        "Sat",
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
      ];

  DateTime _dayDate(int dayIndex) => _weekStart.add(Duration(days: dayIndex));

  // -----------------------
  // API calls
  // -----------------------
  Future<void> _fetchTemplates() async {
    if (_token == null) return;
    setState(() => _loadingTemplates = true);

    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/challenges/templates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );
      

      if (resp.statusCode == 200) {
        final List list = jsonDecode(resp.body);
        setState(() {
          _templates = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        print("TEMPLATE SAMPLE: ${list.isNotEmpty ? list[0] : 'EMPTY'}");

      } else {
        _snack("Failed to load templates (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Templates error: $e");
    } finally {
      setState(() => _loadingTemplates = false);
    }
  }

  Future<void> _fetchKidsForSupervisor() async {
    if (_supervisorId == null) return;
    setState(() => _loadingKids = true);

    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/kidsForSupervisor/$_supervisorId"),
        headers: {
          "Content-Type": "application/json",
          // route عندك بدون auth بس بنبعت التوكن احتياط
          if (_token != null) "Authorization": "Bearer $_token",
        },
      );

      if (resp.statusCode == 200) {
        final List list = jsonDecode(resp.body);
        setState(() {
          _kids = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() => _kids = []);
      }
    } catch (_) {
      setState(() => _kids = []);
    } finally {
      setState(() => _loadingKids = false);
    }
  }

  Future<void> _createTemplateDialog() async {
    final titleCtrl = TextEditingController();
    String selectedCategory = _categories.firstWhere((c) => c != "All", orElse: () => "reading");

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Challenge"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Challenge title (English)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .where((c) => c != "All")
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedCategory = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Create"),
          )
        ],
      ),
    );

    if (created != true) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack("Please enter a title");
      return;
    }

    if (_token == null) return;

    try {
      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/challenges/templates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({
          "title": title,
          "category": selectedCategory,
        }),
      );

      if (resp.statusCode == 201) {
        _snack("Added ✅");
        await _fetchTemplates();
      } else {
        final data = _tryJson(resp.body);
        _snack(data?["error"]?.toString() ?? "Failed (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Error: $e");
    }
  }

  Future<void> _randomWeek() async {
    if (_token == null) return;

    setState(() => _randoming = true);
    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/challenges/random-week"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // best case: backend sends templates array in the same order
        if (data is Map && data["templates"] is List) {
          final List t = data["templates"];
          if (t.length == 7) {
            setState(() {
              for (int i = 0; i < 7; i++) {
                _weekSlots[i] = Map<String, dynamic>.from(t[i]);
              }
            });
            return;
          }
        }

        // fallback: only templateIds
        if (data is Map && data["templateIds"] is List) {
          final List ids = data["templateIds"];
          if (ids.length == 7) {
            final Map<String, Map<String, dynamic>> byId = {
              for (final x in _templates) x["_id"].toString(): x
            };
            setState(() {
              for (int i = 0; i < 7; i++) {
                final id = ids[i].toString();
                _weekSlots[i] = byId[id];
              }
            });
            return;
          }
        }

        _snack("Random week response format not expected");
      } else {
        _snack("Random failed (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Random error: $e");
    } finally {
      setState(() => _randoming = false);
    }
  }

  Future<void> _assignAndSave() async {
    if (_token == null) return;

    // require all 7 days filled
    final ids = _weekSlots.map((t) => t?["_id"]?.toString()).toList();
    if (ids.any((x) => x == null || x!.isEmpty)) {
      _snack("Please fill all 7 days first");
      return;
    }

    // pick kids
    await _openKidsPicker();
    if (_selectedKidIds.isEmpty) {
      _snack("Select at least one child");
      return;
    }

    setState(() => _saving = true);

    try {
      final weekStartStr = DateFormat("yyyy-MM-dd").format(_weekStart);

      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/challenges/weekly-plans"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({
          "childIds": _selectedKidIds.toList(),
          "weekStart": weekStartStr,
          "templateIds": ids,
        }),
      );

      if (resp.statusCode == 201) {
        _snack("Week assigned ✅");
      } else {
        final data = _tryJson(resp.body);
        _snack(data?["error"]?.toString() ?? "Failed (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Save error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _openKidsPicker() async {
    if (_kids.isEmpty) {
      await _fetchKidsForSupervisor();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Assign to Kids",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_loadingKids)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (_kids.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No kids found for this supervisor."),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _kids.length,
                        itemBuilder: (_, i) {
                          final k = _kids[i];
                          final id = k["_id"]?.toString() ?? "";
                          final name = k["name"]?.toString() ?? "Kid";
                          final email = k["email"]?.toString() ?? "";

                          final checked = _selectedKidIds.contains(id);

                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) {
                              setLocal(() {
                                if (v == true) {
                                  _selectedKidIds.add(id);
                                } else {
                                  _selectedKidIds.remove(id);
                                }
                              });
                              setState(() {}); // keep in sync
                            },
                            title: Text(name),
                            subtitle: Text(email),
                            secondary: const Icon(Icons.child_care),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setLocal(() => _selectedKidIds.clear());
                            setState(() {});
                          },
                          child: const Text("Clear"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgWarmPink,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Done (${_selectedKidIds.length})"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -----------------------
  // UI helpers
  // -----------------------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Map<String, dynamic>? _tryJson(String s) {
    try {
      final x = jsonDecode(s);
      if (x is Map<String, dynamic>) return x;
      if (x is Map) return x.map((k, v) => MapEntry(k.toString(), v));
      return null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    final tabCat = _categories[_tabController.index];
    return _templates.where((t) {
      final title = (t["title"] ?? "").toString().toLowerCase();
      final cat = (t["category"] ?? "").toString();
      final matchSearch = _search.isEmpty || title.contains(_search.toLowerCase());
      final matchCat = tabCat == "All" || cat == tabCat;
      return matchSearch && matchCat;
    }).toList();
  }

  Color _badgeColor(String category) {
    // colors from your palette without hardcoding too much
    // Just slight variations with opacity
    switch (category) {
      case "religious":
        return AppColors.bgWarmPink.withOpacity(0.18);
      case "reading":
        return AppColors.peachPink.withOpacity(0.18);
      case "health":
        return Colors.green.withOpacity(0.14);
      case "sport":
        return Colors.blue.withOpacity(0.14);
      case "behavior":
        return Colors.orange.withOpacity(0.14);
      case "art":
        return Colors.purple.withOpacity(0.14);
      case "nature":
        return Colors.teal.withOpacity(0.14);
      default:
        return Colors.grey.withOpacity(0.14);
    }
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeColor(category),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _templateTile(Map<String, dynamic> t) {
    final title = (t["title"] ?? "").toString();
    final cat = (t["category"] ?? "").toString();
final sticker = (t["sticker"] ?? "🎯").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
        CircleAvatar(
  backgroundColor: AppColors.peachPink.withOpacity(0.25),
  child: Text(
    sticker,
    style: const TextStyle(fontSize: 30),
  ),
),

          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _categoryBadge(cat),
            ]),
          ),
          const Icon(Icons.drag_indicator, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _dayCard({
    required int dayIndex,
    required String dayLabel,
    required DateTime date,
    required Map<String, dynamic>? assigned,
    required bool highlight,
    required VoidCallback? onRemove,
  }) {
    final dateStr = DateFormat("MM/dd").format(date);
    final title = (assigned?["title"] ?? "").toString();
    final cat = (assigned?["category"] ?? "").toString();
final sticker = (assigned?["sticker"] ?? "🎯").toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.bgSoftPinkLight : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? AppColors.bgWarmPink : Colors.black12,
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(
                  "$dayLabel  •  $dateStr",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 18, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (assigned == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18, color: Colors.black45),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Drop a challenge here",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            )
         else
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            sticker,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _categoryBadge(cat),
    ],
  ),

        ],
      ),
    );
  }

  Future<void> _pickWeekStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: "Pick any date (week will start on Saturday automatically)",
    );

    if (picked == null) return;
    setState(() {
      _weekStart = _startOfWeekSaturday(picked);
      // optional: clear week when changing
      for (int i = 0; i < 7; i++) _weekSlots[i] = null;
    });
  }

  void _clearWeek() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        _weekSlots[i] = null;
      }
    });
  }

  // -----------------------
  // Build
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final weekTitle =
        "Week: ${DateFormat("yyyy-MM-dd").format(_weekStart)}  →  ${DateFormat("yyyy-MM-dd").format(_weekStart.add(const Duration(days: 6)))}";

    return Scaffold(
      backgroundColor: AppColors.bgSoftPinkLight,
      appBar: AppBar(
        backgroundColor: AppColors.peachPink,
        title: const Text("Weekly Challenges"),
        actions: [
          IconButton(
            onPressed: _loading
                ? null
                : () async {
                    await _fetchTemplates();
                    await _fetchKidsForSupervisor();
                    _snack("Refreshed ✅");
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TOP: week header + actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ✅ FIXED BUTTONS LAYOUT (NO MORE SQUEEZED)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickWeekStart,
                                icon: const Icon(Icons.date_range),
                                label: const Text("Change Week"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _randoming ? null : _randomWeek,
                                icon: _randoming
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.casino_outlined),
                                label: const Text("Random Week"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _clearWeek,
                                icon: const Icon(Icons.cleaning_services_outlined),
                                label: const Text("Clear"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _createTemplateDialog,
                                icon: const Icon(Icons.add),
                                label: const Text("Add Challenge"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ✅ Assign button alone full width
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgWarmPink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _saving ? null : _assignAndSave,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text(
                              "Assign & Save",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // WEEK BOARD (7 days)
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final assigned = _weekSlots[i];
                      final dayLabel = _dayLabels()[i];
                      final date = _dayDate(i);

                      return SizedBox(
                        width: 210,
                        child: DragTarget<Map<String, dynamic>>(
                          onWillAccept: (_) => true,
                          onAccept: (template) {
                            setState(() => _weekSlots[i] = template);
                          },
                          builder: (context, candidate, rejected) {
                            return _dayCard(
                              dayIndex: i,
                              dayLabel: dayLabel,
                              date: date,
                              assigned: assigned,
                              highlight: candidate.isNotEmpty,
                              onRemove: assigned == null
                                  ? null
                                  : () {
                                      setState(() => _weekSlots[i] = null);
                                    },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Search + Tabs + Templates list
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: InputDecoration(
                      hintText: "Search challenges...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.bgWarmPinkDark,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.bgWarmPinkDark,
                  onTap: (_) => setState(() {}),
                  tabs: _categories.map((c) => Tab(text: c)).toList(),
                ),

                Expanded(
                  child: _loadingTemplates
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _fetchTemplates,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            children: [
                              if (_filteredTemplates.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text("No challenges found."),
                                )
                              else
                                ..._filteredTemplates.map((t) {
                                  return Draggable<Map<String, dynamic>>(
                                    data: t,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width * 0.85,
                                        child: Opacity(
                                          opacity: 0.95,
                                          child: _templateTile(t),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.35,
                                      child: _templateTile(t),
                                    ),
                                    child: _templateTile(t),
                                  );
                                }),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
