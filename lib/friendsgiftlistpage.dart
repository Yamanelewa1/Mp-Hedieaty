import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsGiftListPage extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String friendProfilePicture;

  FriendsGiftListPage({
    required this.friendId,
    required this.friendName,
    required this.friendProfilePicture,
  });

  @override
  _FriendsGiftListPageState createState() => _FriendsGiftListPageState();
}

class _FriendsGiftListPageState extends State<FriendsGiftListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friendName}'s Events"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlueAccent.shade100, Colors.lightBlueAccent.shade400],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('events')
              .where('creatorId', isEqualTo: widget.friendId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error fetching events.',
                      style: TextStyle(color: Colors.black54)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('No events found.',
                      style: TextStyle(color: Colors.black54)));
            }

            final events = snapshot.data!.docs;

            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index].data() as Map<String, dynamic>;

                return Card(
                  color: Colors.lightBlue.shade50,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      event['name'] ?? 'Unnamed Event',
                      style: TextStyle(
                          color: Colors.lightBlue.shade900,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Date: ${event['date'] ?? 'N/A'}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.lightBlue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventGiftListPage(
                            eventId: events[index].id,
                            eventName: event['name'] ?? 'Unnamed Event',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EventGiftListPage extends StatefulWidget {
  final String eventId;
  final String eventName;

  EventGiftListPage({
    required this.eventId,
    required this.eventName,
  });

  @override
  _EventGiftListPageState createState() => _EventGiftListPageState();
}

class _EventGiftListPageState extends State<EventGiftListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isValidBase64(String? value) {
    if (value == null || value.isEmpty) return false;
    try {
      base64Decode(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _modifyGiftStatus(String giftId, String action) async {
    try {
      if (action == 'pledged') {
        await _firestore
            .collection('events')
            .doc(widget.eventId)
            .collection('gifts')
            .doc(giftId)
            .update({'status': 'pledged'});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift status updated to pledged!')),
        );
      }
    } catch (e) {
      print('Error modifying gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update gift status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.eventName}'s Gifts"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlueAccent.shade100, Colors.lightBlueAccent.shade400],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('events')
              .doc(widget.eventId)
              .collection('gifts')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error fetching gifts.',
                      style: TextStyle(color: Colors.black54)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('No gifts found.',
                      style: TextStyle(color: Colors.black54)));
            }

            final gifts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index].data() as Map<String, dynamic>;
                final giftId = gifts[index].id;
                final isPledged = gift['status'] == 'pledged';

                return Card(
                  color: isPledged ? Colors.lightGreen.shade100 : Colors.lightBlue.shade100,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: _isValidBase64(gift['image'])
                        ? Image.memory(
                      base64Decode(gift['image']),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Icon(Icons.card_giftcard, color: Colors.lightBlue),
                    title: Text(
                      gift['name'] ?? 'Unnamed Gift',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue.shade900,
                      ),
                    ),
                    subtitle: Text(
                      "Category: ${gift['category'] ?? 'N/A'}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: isPledged
                        ? Icon(Icons.lock, color: Colors.grey)
                        : PopupMenuButton<String>(
                      onSelected: (value) => _modifyGiftStatus(giftId, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pledged',
                          child: Text('Mark as Pledged'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
