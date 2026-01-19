

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'].toString(),
      senderId: json['sender'] is Map
          ? json['sender']['_id'].toString()
          : json['sender'].toString(),
      receiverId: json['receiver'] is Map
          ? json['receiver']['_id'].toString()
          : json['receiver'].toString(),
      message: json['message'].toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ChatSocketService {
  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io('${getBackendUrl()}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected: ${socket.id}');
      socket.emit('join', userId);
    });
  }

  void sendMessage(String senderId, String receiverId, String message) {
    socket.emit(
      'sendMessage',
      {'senderId': senderId, 'receiverId': receiverId, 'message': message},
    );
  }

  void onReceiveMessage(void Function(dynamic) callback) {
    socket.on('receiveMessage', callback);
  }

  void onTyping(void Function(dynamic) callback) {
    socket.on('typing', callback);
  }

  void emitTyping(String senderId, String receiverId, bool isTyping) {
    socket.emit('typing', {'senderId': senderId, 'receiverId': receiverId, 'isTyping': isTyping});
  }
}

class ChatUsersScreen extends StatefulWidget {
  final String currentUserId;

  const ChatUsersScreen({super.key, required this.currentUserId});

  @override
  State<ChatUsersScreen> createState() => _ChatUsersScreenState();
}

class _ChatUsersScreenState extends State<ChatUsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String userId = "";
  String role = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> _fetchUsers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];
      role = decodedToken['role'];

      List<Map<String, dynamic>> filteredUsers = [];

      if (role == "child") {
        // Fetch supervisor
        final childResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getme/$userId"),
          headers: {"Content-Type": "application/json"},
        );

        if (childResponse.statusCode == 200) {
          final childData = jsonDecode(childResponse.body);
          final supervisorId = childData['supervisorId'];

          if (supervisorId != null) {
            final supResponse = await http.get(
              Uri.parse("${getBackendUrl()}/api/users/getme/$supervisorId"),
              headers: {"Content-Type": "application/json"},
            );

            if (supResponse.statusCode == 200) {
              final sup = jsonDecode(supResponse.body);
            //  filteredUsers.add({"id": sup["_id"], "name": sup["name"]});
            filteredUsers.add({
  "id": sup["_id"],
  "name": sup["name"],
  "image": sup["profilePicture"], // 👈 add this
});

            }
          }
        }
      } else if (role == "parent") {
        // Fetch kids' supervisors
        final kidsResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getParentKids/$userId"),
          headers: {"Content-Type": "application/json"},
        );

        if (kidsResponse.statusCode == 200) {
          final kids = jsonDecode(kidsResponse.body) as List;
          for (var kid in kids) {
          final supId = kid['supervisorId'];

            if (supId != null) {
              final supResponse = await http.get(
                Uri.parse("${getBackendUrl()}/api/users/getme/$supId"),
                headers: {"Content-Type": "application/json"},
              );
              if (supResponse.statusCode == 200) {
                final sup = jsonDecode(supResponse.body);
                print("Supervisor fot the kids : $sup");
                filteredUsers.add({
  "id": sup["_id"],
  "name": sup["name"],
  "image": sup["profilePicture"], // 👈 add this
});

              }
            }
          }
        }
   
      } 
      else if (role == "supervisor") {
        // Get kids + parents + admins
        final kidsResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/kidsForSupervisor/$userId"),
          headers: {"Content-Type": "application/json"},
        );

        if (kidsResponse.statusCode == 200) {
          final kids = jsonDecode(kidsResponse.body) as List;
          for (var kid in kids) {
       //     filteredUsers.add({"id": kid["_id"], "name": kid["name"]});
       filteredUsers.add({
  "id": kid["_id"],
  "name": kid["name"],
  "image": kid["profilePicture"], // 👈 add this
});

            if (kid['parentId'] != null) {
              final parentResponse = await http.get(
                Uri.parse("${getBackendUrl()}/api/users/getme/${kid['parentId']}"),
                headers: {"Content-Type": "application/json"},
              );
              if (parentResponse.statusCode == 200) {
                final parent = jsonDecode(parentResponse.body);
              filteredUsers.add({
  "id": parent["_id"],
  "name": parent["name"],
  "image": parent["profilePicture"], // 👈 add this
});

              }
            }
          }
        }

        final adminsResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getAdmins/"),
          headers: {"Content-Type": "application/json"},
        );

        if (adminsResponse.statusCode == 200) {
          final admins = jsonDecode(adminsResponse.body) as List;
          for (var admin in admins) {
           // filteredUsers.add({"id": admin["_id"], "name": admin["name"]});
           filteredUsers.add({
  "id": admin["_id"],
  "name": admin["name"],
  "image": admin["profilePicture"], // 👈 add this
});

          }
        }
      } else if (role == "admin") {
        // Fetch supervisors + other admins
        final supResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getSupervisors/"),
          headers: {"Content-Type": "application/json"},
        );
        if (supResponse.statusCode == 200) {
          final supervisors = jsonDecode(supResponse.body) as List;
          for (var sup in supervisors) {
          //  filteredUsers.add({"id": sup["_id"], "name": sup["name"]});
          filteredUsers.add({
  "id": sup["_id"],
  "name": sup["name"],
  "image": sup["profilePicture"], // 👈 add this
});

          }
        }

        final adminsResponse = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getAdmins/"),
          headers: {"Content-Type": "application/json"},
        );
        if (adminsResponse.statusCode == 200) {
          final admins = jsonDecode(adminsResponse.body) as List;
          for (var admin in admins) {
            if (admin["_id"] != userId) {
              filteredUsers.add({"id": admin["_id"], "name": admin["name"]});
            }
          }
        }
      }

      // Remove duplicates
      final ids = <String>{};
      filteredUsers = filteredUsers.where((u) => ids.add(u['id'])).toList();

      setState(() {
        users = filteredUsers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoading = false);
    }
  }


  @override
Widget build(BuildContext context) {
  return HomePage(
  //  backgroundColor: const Color(0xFFFFF6E5),
      title: " Users List 💬",
    child: Container(
      decoration: const BoxDecoration(
        color: const Color(0xFFFFF6E5),

      ),
     
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6E4A4A).withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
             
          child:  ListTile(
  leading: KidAvatar(
    name: user['name'], 
    image: user['image'], 
    index: index,
  ),
  title: Text(
    user['name'] ?? "Unknown",
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: widget.currentUserId,
          otherUserId: user['id'],
        ),
      ),
    );
  },
),


            //    )
              );
            },
          ),
  ),
  );
}

}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({super.key, required this.currentUserId, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatSocketService _socketService = ChatSocketService();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _socketService.connect(widget.currentUserId);

    _socketService.onReceiveMessage((data) {
      final message = ChatMessage.fromJson(data);
      setState(() => messages.add(message));
      _scrollToBottom();
    });

    _socketService.onTyping((data) {
      if (data['senderId'] == widget.otherUserId) {
        setState(() => isTyping = data['isTyping']);
      }
    });

    _loadChatHistory();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse("${_socketService.getBackendUrl()}/api/chat/conversation/${widget.otherUserId}"),
        headers: {
          "Content-Type": "application/json",
         // "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List chats = data['chats'];
        setState(() {
          messages = chats.map((e) => ChatMessage.fromJson(e)).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error loading chat history: $e");
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse("${_socketService.getBackendUrl()}/api/chat/send"),
      headers: {
        "Content-Type": "application/json",
        //"Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "receiverId": widget.otherUserId,
        "message": text,
      }),
    );

    if (response.statusCode == 200) {
      final chat = jsonDecode(response.body)['chat'];
      _socketService.socket.emit("sendMessage", {"chat": chat});

      setState(() {
        messages.add(ChatMessage.fromJson(chat));
        _controller.clear();
      });
      _scrollToBottom();
    }
  }


  @override
Widget build(BuildContext context) {

 if (!kIsWeb) {
    return Scaffold (
    backgroundColor: const Color(0xFFFFF6E5),
    appBar: AppBar(
title: const Text(
  "Chat Time 🧸",
  style: TextStyle(
    color: Colors.brown,
    fontWeight: FontWeight.bold,
  ),
),

      centerTitle: true,
      backgroundColor:  AppColors.warmHoneyYellow,
      elevation: 0,
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.senderId == widget.currentUserId;

              return Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _ChatBubble(message: msg.message, isMe: isMe),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat('hh:mm a').format(msg.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        if (isTyping)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: const [
                Icon(Icons.more_horiz, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  "Typing...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message ✨",
                      filled: true,
                      fillColor: const Color(0xFFFFF1C1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (text) {
                      _socketService.emitTyping(
                        widget.currentUserId,
                        widget.otherUserId,
                        text.isNotEmpty,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFB703),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
} else
   return HomePage (
    title: 
  "Chat Time 🧸",

    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.senderId == widget.currentUserId;

              return Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _ChatBubble(message: msg.message, isMe: isMe),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat('hh:mm a').format(msg.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        if (isTyping)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: const [
                Icon(Icons.more_horiz, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  "Typing...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message ✨",
                      filled: true,
                      fillColor: const Color(0xFFFFF1C1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (text) {
                      _socketService.emitTyping(
                        widget.currentUserId,
                        widget.otherUserId,
                        text.isNotEmpty,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFB703),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [const Color.fromARGB(255, 119, 87, 75), const Color.fromARGB(255, 154, 114, 99)])
              : LinearGradient(colors: [const Color.fromARGB(255, 235, 228, 176), const Color.fromARGB(255, 246, 237, 165)]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}


class KidAvatar extends StatelessWidget {
  final String name;
  final Map<String, dynamic>? image;
  final int index;

  const KidAvatar({
    super.key,
    required this.name,
    required this.image,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFF6F91),
      const Color(0xFFFF9671),
      const Color(0xFFFFC75F),
      const Color(0xFF4D96FF),
      const Color(0xFF6BCB77),
      const Color(0xFF845EC2),
    ];

    final bgColor = colors[index % colors.length];

    // 🧠 SAME LOGIC AS CODE 2
    final imageBytes = image?["data"]?["data"];

    Widget avatarChild;

    if (imageBytes != null && imageBytes is List) {
      avatarChild = ClipOval(
        child: Image.memory(
          Uint8List.fromList(List<int>.from(imageBytes)),
          fit: BoxFit.cover,
          width: 52,
          height: 52,
        ),
      );
    } else {
    avatarChild = Text(
  name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?",
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
);

    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: bgColor,
      child: avatarChild,
    );
  }
}
