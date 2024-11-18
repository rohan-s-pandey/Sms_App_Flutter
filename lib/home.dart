import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> smsList = [];
  List<SmsMessage> chatMessages = [];
  List<SmsMessage> notificationMessages = [];
  Map<String, SmsMessage> latestMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchSms();
  }

  // Fetch SMS messages from inbox
  Future<void> _fetchSms() async {
    List<SmsMessage> messages = await _query.getAllSms;
    _categorizeMessages(messages);
  }

  // Categorize messages and keep only the latest message per contact
  Future<void> _categorizeMessages(List<SmsMessage> messages) async {
    List<Contact> contacts =
        await FlutterContacts.getContacts(withProperties: true);

    setState(() {
      smsList = messages;
      chatMessages.clear();
      notificationMessages.clear();
      latestMessages.clear();

      for (var message in messages) {
        bool isInContacts = contacts.any((contact) {
          return contact.phones.any((phone) => phone.number == message.sender);
        });

        if (isInContacts) {
          chatMessages.add(message);
        } else if (_isShortcode(message.sender)) {
          notificationMessages.add(message);
        } else if (_containsNotificationKeywords(message.body)) {
          notificationMessages.add(message);
        } else {
          notificationMessages.add(message);
        }

        // Update the latest message for each sender
        if (message.sender != null) {
          // If the sender already exists in the map, replace if the current message is newer
          if (!latestMessages.containsKey(message.sender) ||
              message.dateSent != null &&
                  message.dateSent!.isAfter(
                      latestMessages[message.sender]!.dateSent ??
                          DateTime(0))) {
            latestMessages[message.sender!] = message;
          }
        }
      }
    });
  }

  bool _isShortcode(String? sender) {
    if (sender == null) return false;
    final shortcodeRegExp = RegExp(r'^\d{5,6}$');
    return shortcodeRegExp.hasMatch(sender);
  }

  bool _containsNotificationKeywords(String? body) {
    if (body == null) return false;
    final keywords = [
      'OTP',
      'offer',
      'discount',
      'promo',
      'alert',
      'bank',
      'transaction'
    ];
    return keywords
        .any((keyword) => body.toLowerCase().contains(keyword.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMS App')),
      body: Column(
        children: [
          // Chat Messages with Latest Message
          Expanded(
            child: ListView.builder(
              itemCount: latestMessages.length,
              itemBuilder: (context, index) {
                String sender = latestMessages.keys.elementAt(index);
                SmsMessage latestMessage = latestMessages[sender]!;
                return ListTile(
                  title: Text(sender),
                  subtitle: Text(latestMessage.body ?? ''),
                );
              },
            ),
          ),
          // Notification Messages
          Expanded(
            child: ListView.builder(
              itemCount: notificationMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      notificationMessages[index].sender ?? "Unknown sender"),
                  subtitle: Text(notificationMessages[index].body ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
