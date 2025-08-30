import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String chatId;
  final Color? avatarColor;
  final String? heroTag;
  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.chatId,
    this.avatarColor,
    this.heroTag,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(dt);
  }

  bool _isSameDay(Timestamp a, Timestamp b) {
    final da = a.toDate();
    final db = b.toDate();
    return da.year == db.year && da.month == db.month && da.day == db.day;
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

    Widget frosted({required Widget child, double radius = 16, EdgeInsets? padding}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Hero(
              tag: widget.heroTag ?? 'avatar_${widget.peerId}',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: widget.avatarColor ?? cs.primary,
                child: Text(
                  widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background
          gradientBackground(),
          Positioned(
top: -80,
left: -60,
child: Hero(
tag: 'riblob',
child: blob(220, cs.primary.withOpacity(0.18)),
),
),
Positioned(
bottom: -70, 
right: -50,
child: Hero(
tag: 'lfblob',
child: blob(200, cs.secondary.withOpacity(0.16)),
),
),

          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: chat.messagesStream(widget.chatId),
                    builder: (_, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final msgs = snap.data!;
                      if (msgs.isEmpty) {
                        return Center(
                          child: frosted(
                            child: const Text('Say hi 👋', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final isMe = m.fromId == me.uid;
                          final showHeader = i == 0 || !_isSameDay(m.createdAt, msgs[i - 1].createdAt);

                          final bubble = _MessageBubble(
                            text: m.text ?? '',
                            isMe: isMe,
                            time: DateFormat.jm().format(m.createdAt.toDate()),
                            cs: cs,
                          );

                          if (showHeader) {
                            return Column(
                              children: [
                                const SizedBox(height: 6),
                                _DateChip(label: _dateLabel(m.createdAt.toDate()), cs: cs),
                                const SizedBox(height: 8),
                                bubble,
                              ],
                            );
                          }
                          return bubble;
                        },
                      );
                    },
                  ),
                ),
                _Composer(
                  controller: _ctrl,
                  cs: cs,
                  onSend: () async {
                    final text = _ctrl.text.trim();
                    if (text.isEmpty) return;
                    _ctrl.clear();
                    await chat.sendText(
                      chatId: widget.chatId,
                      fromId: me.uid,
                      toId: widget.peerId,
                      text: text,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _DateChip({required this.label, required this.cs});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final ColorScheme cs;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? null : cs.surface.withOpacity(0.6);
    final gradient = isMe
        ? LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final txtColor = isMe ? Colors.white : cs.onSurface;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: bg,
        gradient: gradient,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SelectableText(
            text,
            style: TextStyle(color: txtColor, fontSize: 15, height: 1.25),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, style: TextStyle(color: txtColor.withOpacity(0.9), fontSize: 11)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_rounded, size: 14, color: txtColor.withOpacity(0.95)),
              ],
            ],
          ),
        ],
      ),
    );

    if (!isMe) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: bubble,
          ),
        ),
      );
    }

    return Align(alignment: Alignment.centerRight, child: bubble);
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ColorScheme cs;
  const _Composer({required this.controller, required this.onSend, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                      filled: true,
                      fillColor: cs.surface.withOpacity(0.6),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}