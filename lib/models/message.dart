import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String fromId;
  final String toId;
  final String? text;
  final Timestamp createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.fromId,
    required this.toId,
    required this.createdAt,
    this.text,
  });

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'fromId': fromId,
        'toId': toId,
        'text': text,
        'createdAt': createdAt,
      };

  static Message fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Message(
      id: doc.id,
      chatId: d['chatId'],
      fromId: d['fromId'],
      toId: d['toId'],
      text: d['text'],
      createdAt: d['createdAt'],
    );
  }
}