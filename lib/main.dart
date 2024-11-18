import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smsapp/chat_screen.dart';

void main() {
  runApp(SmsApp());
}

class SmsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMS App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SmsHomePage(),
    );
  }
}

class SmsHomePage extends StatefulWidget {
  @override
  _SmsHomePageState createState() => _SmsHomePageState();
}

class _SmsHomePageState extends State<SmsHomePage> {
  final SmsQuery _smsQuery = SmsQuery();
  List<SmsMessage> _chatMessages = [];
  List<SmsMessage> _notificationMessages = [];
  Map<String, String> _contactsMap = {};
  bool _isLoading = false;
  int _currentIndex =
      0; // To track the selected tab (Chat SMS or Notifications)

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _checkPermissionsAndFetchMessages();
  }

  // Check permissions and fetch messages
  Future<void> _checkPermissionsAndFetchMessages() async {
    PermissionStatus status = await Permission.sms.request();

    if (status.isGranted) {
      _fetchMessages();
    } else {
      // Show a snackbar if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("SMS permission is required to fetch messages."),
      ));
    }
  }

  Future<void> _fetchContacts() async {
    List<Contact> contacts =
        await FlutterContacts.getContacts(withProperties: true);
    setState(() {
      _contactsMap = {
        for (var contact in contacts)
          contact.phones.first.number: contact.displayName
      };
    });
  }

  // Fetch SMS messages and categorize them
  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<SmsMessage> messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 100, // Fetch the most recent 100 messages
      );

      // Use maps to group the last message by sender
      Map<String, SmsMessage> chatMessagesMap = {};
      Map<String, SmsMessage> notificationMessagesMap = {};

      List<Contact> contacts =
          await FlutterContacts.getContacts(withProperties: true);

      for (var message in messages) {
        if (_isChatMessage(message, contacts)) {
          chatMessagesMap[message.address ?? 'Unknown'] = message;
        } else {
          notificationMessagesMap[message.address ?? 'Unknown'] = message;
        }
      }

      setState(() {
        // Convert the maps to lists to display only the latest message from each sender
        _chatMessages = chatMessagesMap.values.toList();
        _notificationMessages = notificationMessagesMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching messages: $e');
    }
  }

  // Method to categorize SMS messages as Chat or Notification
  bool _isChatMessage(SmsMessage message, List<Contact> contacts) {
    // Check if the sender is in the contact list
    bool isInContacts = contacts.any((contact) {
      return contact.phones.any((phone) {
        return phone.number == message.address;
      });
    });

    // If sender is in contacts, it's a Chat message
    if (isInContacts) {
      return true;
    }

    // Check if the sender is a known shortcode (5-6 digits) - These are often used for Notifications
    if (_isShortcode(message.address)) {
      return false; // This is a Notification, not a Chat SMS
    }

    // If the message contains keywords like "OTP" or "Offer", it's considered a Notification
    if (_containsNotificationKeywords(message.body)) {
      return false; // This is a Notification
    }

    return true; // Otherwise, it's a Chat SMS
  }

  // Check if the sender is a known shortcode (usually 5-6 digits)
  bool _isShortcode(String? sender) {
    if (sender == null) return false;
    final shortcodeRegExp =
        RegExp(r'^\d{5,6}$'); // 5-6 digit number (e.g., 12345 or 567890)
    return shortcodeRegExp.hasMatch(sender);
  }

  // Check if the message contains common notification keywords
  bool _containsNotificationKeywords(String? body) {
    if (body == null) return false;
    final keywords = [
      'OTP',
      'offer',
      'discount',
      'promo',
      'alert',
      'bank',
      'transaction',
      'payment',
      'credit',
      'debit',
      'http',
      'https',
      'kyc',
      'recharge',
      'T&C',
      'Airtel',
      'loan',
      'balance',
      'withdrawal',
      'deposit',
      'card',
      'UPI',
      'cashback',
      'promo code',
      'EMI',
      'due date',
      'limit',
      'investment',
      'rewards',
      'बैंक',
      'लेनदेन',
      'भुगतान',
      'क्रेडिट',
      'डेबिट',
      'http',
      'https',
      'नमस्ते',
      'केवाईसी',
      'रीचार्ज',
      'नियम और शर्तें',
      'अलर्ट',
      'बैलेंस',
      'निकासी',
      'जमा',
      'लोन',
      'सौदा',
      'उपहार',
      'रिवॉर्ड्स',
      'उधार',
      'सीमित अवधि',
      'सावधान',
      'मोबाइल',
      'सुविधा',
      'ऑफर',
      'डिस्काउंट'
    ];
    return keywords
        .any((keyword) => body.toLowerCase().contains(keyword.toLowerCase()));
  }

  // Widget to display the list of SMS messages
  // Inside your _buildSmsList method in SmsHomePage
  Widget _buildSmsList(List<SmsMessage> messages) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        SmsMessage message = messages[index];
        String sender = _contactsMap[message.address] ??
            message.address ??
            'Unknown Sender';

        return ListTile(
          leading: Icon(Icons.message),
          title: Text(sender),
          subtitle: Text(message.body ?? 'No Content'),
          trailing: Text(
            message.date != null
                ? DateTime.fromMillisecondsSinceEpoch(
                        message.date!.millisecondsSinceEpoch)
                    .toString()
                : '',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () {
            // Navigate to the ChatScreen when the user taps on a contact
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  contactName: sender,
                  phoneNumber: message.address ?? '',
                  userPhoneNumber: '',
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS App'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentIndex == 0
              ? _buildSmsList(_chatMessages) // Show Chat SMS
              : _buildSmsList(_notificationMessages), // Show Notifications
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
