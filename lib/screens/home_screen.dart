import 'dart:ui';
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
    return HSLColor.fromAHSL(
      1,
      hue,
      0.55,
      scheme.brightness == Brightness.dark ? 0.45 : 0.70,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final chat = context.read<ChatService>();
    final cs = Theme.of(context).colorScheme;

    Widget gradientBackground() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.10),
              cs.secondary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    Widget blob(double size, Color color, {Alignment align = Alignment.center}) {
      return Align(
        alignment: align,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      );
    }

    Widget frosted({required Widget child, double radius = 20, EdgeInsets? padding, EdgeInsets? margin}) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding ?? const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          gradientBackground(),
          Positioned(
            top: -80,
            right: -60,
            child: Hero(
              tag: 'riblob',
              child: blob(220, cs.primary.withOpacity(0.18)),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: Hero(
              tag: 'lfblob',
              child: blob(200, cs.secondary.withOpacity(0.16)),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  frosted(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search people',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            child: frosted(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 72, color: cs.outline),
                                  const SizedBox(height: 12),
                                  Text('No people found', style: TextStyle(color: cs.onSurface.withOpacity(0.8))),
                                  const SizedBox(height: 6),
                                  Text('Create another account to test chatting.',
                                      style: TextStyle(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(top: 6, bottom: 8),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = users[i];
                            final name = (u['displayName'] ?? u['email'] ?? 'User') as String;
                            final tag = 'avatar_${u['uid']}';
                            final color = _avatarColorFrom(u['uid'], cs);

                            return frosted(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: ListTile(
                                onTap: () {
                                  final chatId = chat.chatIdFor(me.uid, u['uid']);
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      peerId: u['uid'],
                                      peerName: name,
                                      chatId: chatId,
                                      avatarColor: color,
                                      heroTag: tag,
                                    ),
                                  ));
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Hero(
                                  tag: tag,
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: color,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  u['email'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [cs.primary, cs.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        );
                      },
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