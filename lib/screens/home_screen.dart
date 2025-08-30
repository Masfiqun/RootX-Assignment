import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _q = '';

  Color _avatarColorFrom(String seed, ColorScheme scheme) {
    final hash = seed.codeUnits.fold<int>(0, (p, c) => p + c);
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, scheme.brightness == Brightness.dark ? 0.45 : 0.65).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final chat = context.read<ChatService>();
    final cs = Theme.of(context).colorScheme;

    Widget gradientAppBarBackground() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(0.12), cs.secondary.withOpacity(0.06)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        flexibleSpace: gradientAppBarBackground(),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chat.usersStream(me.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var users = snap.data ?? [];
                if (_q.isNotEmpty) {
                  users = users.where((u) {
                    final n = (u['displayName'] ?? '').toString().toLowerCase();
                    final e = (u['email'] ?? '').toString().toLowerCase();
                    return n.contains(_q) || e.contains(_q);
                  }).toList();
                }
                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 72, color: cs.outline),
                          const SizedBox(height: 12),
                          Text('No people found', style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 4),
                          Text('Create another account to test chatting.',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final name = (u['displayName'] ?? u['email'] ?? 'User') as String;
                    final tag = 'avatar_${u['uid']}';
                    final color = _avatarColorFrom(u['uid'], cs);
                    return Card(
                      child: ListTile(
                        onTap: () {
                          final chatId = chat.chatIdFor(me.uid, u['uid']);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              peerId: u['uid'], peerName: name, chatId: chatId, avatarColor: color, heroTag: tag,
                            ),
                          ));
                        },
                        leading: Hero(
                          tag: tag,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: color,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(u['email'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}