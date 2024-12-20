import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'giftlistpage.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  List<QueryDocumentSnapshot> _events = [];
  List<String> _friendIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      await _fetchFriends();
      await _fetchFriendEvents();
    }
  }

  Future<void> _fetchFriends() async {
    try {
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .get();

      setState(() {
        _friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching friends: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch friends. Please try again.')),
      );
    }
  }

  Future<void> _fetchFriendEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<String> eventCreatorIds = [..._friendIds, currentUserId!];

      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('creatorId', whereIn: eventCreatorIds)
          .get();

      setState(() {
        _events = eventSnapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch events. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createEvent(String name, String date) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('events').add({
        'name': name,
        'date': date,
        'creatorId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(currentUserId).update({
        'upcomingEvent': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event created successfully.')),
      );
      _fetchFriendEvents();
    } catch (e) {
      print('Error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event.')),
      );
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event deleted successfully.')),
      );
      _fetchFriendEvents();
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event.')),
      );
    }
  }

  void _showCreateEventDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Event', style: TextStyle(color: Colors.deepPurple)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Event Date',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    dateController.text.isNotEmpty) {
                  _createEvent(
                      nameController.text.trim(), dateController.text.trim());
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All fields are required.')),
                  );
                }
              },
              child: Text('Create', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friend’s Events',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent.shade700,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: Colors.amber.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.blueAccent.shade400],
          ),
        ),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : _events.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.white70),
              SizedBox(height: 10),
              Text(
                'No events found.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index].data() as Map<String, dynamic>;
            final isOwner = event['creatorId'] == currentUserId;

            return Card(
              margin: EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 6,
              color: Colors.white,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 16.0),
                title: Text(
                  event['name'] ?? 'Unnamed Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade700,
                  ),
                ),
                subtitle: Text(
                  "Date: ${event['date'] ?? 'N/A'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                trailing: isOwner
                    ? IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _deleteEvent(_events[index].id),
                )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GiftListPage(
                        eventId: _events[index].id,
                        eventName: event['name'] ?? 'Unnamed Event',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }




}
