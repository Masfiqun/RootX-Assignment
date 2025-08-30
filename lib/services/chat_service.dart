import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String chatIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<Map<String, dynamic>>> usersStream(String currentUid) {
    return _db.collection('users')
      .orderBy('displayName', descending: false)
      .snapshots()
      .map((s) => s.docs
        .where((d) => d.id != currentUid)
        .map((d) => {'uid': d.id, ...?d.data()})
        .toList());
  }

  Stream<List<Message>> messagesStream(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  Future<void> sendText({
    required String chatId,
    required String fromId,
    required String toId,
    required String text,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    // Create/update the chat doc so rules know the members
    await chatRef.set({
      'members': [fromId, toId],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final msgRef = chatRef.collection('messages').doc();
    final msg = Message(
      id: msgRef.id,
      chatId: chatId,
      fromId: fromId,
      toId: toId,
      text: text,
      createdAt: Timestamp.now(),
    );
    await msgRef.set(msg.toMap());
  }
}