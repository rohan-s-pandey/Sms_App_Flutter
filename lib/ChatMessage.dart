class ChatMessage {
  final String sender;
  final String body;
  final DateTime date;
  final bool isSentByMe;

  ChatMessage({
    required this.sender,
    required this.body,
    required this.date,
    required this.isSentByMe,
  });
}
