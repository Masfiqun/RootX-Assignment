import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final chat = context.read<ChatService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chat.usersStream(me.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('No other users yet.\nCreate another account to test.', textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final name = (u['displayName'] ?? u['email'] ?? 'User') as String;
              return ListTile(
                leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                title: Text(name),
                subtitle: Text(u['email'] ?? ''),
                onTap: () {
                  final chatId = chat.chatIdFor(me.uid, u['uid']);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      peerId: u['uid'],
                      peerName: name,
                      chatId: chatId,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}