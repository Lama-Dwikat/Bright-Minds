import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --------------------
// Game Model
// --------------------
class Game {
  final String id;
  final String title;
  final String thumbnail;
  final String genre;
  final List<String> platform;
  final String description;

  Game({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.genre,
    required this.platform,
    required this.description,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'],
      title: json['title'],
      thumbnail: json['thumbnail'],
      genre: json['genre'],
      platform: List<String>.from(json['platform'] ?? []),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "thumbnail": thumbnail,
      "genre": genre,
      "platform": platform,
      "description": description,
    };
  }
}

// --------------------
// Game Service
// --------------------
class GameService {
  static const String baseUrl = "http://localhost:3000/api/games";

  static Future<List<Game>> fetchGames() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load games");
    }
  }

  static Future<Game> fetchGame(String id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Game.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch game");
    }
  }

  static Future<Game> createGame(Game game) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(game.toJson()),
    );
    if (response.statusCode == 201) {
      return Game.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to create game");
    }
  }

  static Future<Game> updateGame(String id, Game game) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(game.toJson()),
    );
    if (response.statusCode == 200) {
      return Game.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update game");
    }
  }

  static Future<void> deleteGame(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete game");
    }
  }
}

// --------------------
// Game Page UI
// --------------------
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late Future<List<Game>> games;

  @override
  void initState() {
    super.initState();
    games = GameService.fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Games")),
      body: FutureBuilder<List<Game>>(
        future: games,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final gameList = snapshot.data!;

          return ListView.builder(
            itemCount: gameList.length,
            itemBuilder: (context, index) {
              final game = gameList[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: Image.network(
                    game.thumbnail,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    game.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Genre: ${game.genre}"),
                      Text("Platforms: ${game.platform.join(", ")}"),
                      const SizedBox(height: 5),
                      Text(
                        game.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to Game Detail Page
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
