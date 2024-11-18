import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;

  ChatScreen(
      {required this.phoneNumber,
      required this.contactName,
      required String userPhoneNumber});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SmsQuery _smsQuery = SmsQuery();
  final TextEditingController _controller = TextEditingController();
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    PermissionStatus status = await Permission.sms.request();
    if (status.isGranted) {
      try {
        final messages = await _smsQuery.querySms(
          address: widget.phoneNumber,
          kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
        );

        setState(() {
          _messages = messages
              .map((sms) => MessageModel(
                    body: sms.body ?? '',
                    isSentByMe: sms.kind == SmsMessageKind.sent,
                    timestamp: sms.date ?? DateTime.now(),
                  ))
              .toList();
          // Sort messages by timestamp in ascending order
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch messages: $e")),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SMS permission is required.")),
      );
    }
  }

  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return Align(
          alignment:
              message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: message.isSentByMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message.body,
              style: TextStyle(
                color: message.isSentByMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(
          MessageModel(
            body: _controller.text,
            isSentByMe: true,
            timestamp: DateTime.now(),
          ),
        );
        _controller.clear();
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      // Replace this with actual SMS sending logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message sent (simulated).")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.contactName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom model for chat messages
class MessageModel {
  final String body;
  final bool isSentByMe;
  final DateTime timestamp;

  MessageModel({
    required this.body,
    required this.isSentByMe,
    required this.timestamp,
  });
}
