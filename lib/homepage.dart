import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'ProfilePage.dart';
import 'giftlistpage.dart';
import 'EventListPage.dart';
import 'friendsgiftlistpage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _manualPhoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<QueryDocumentSnapshot> _friends = [];
  List<QueryDocumentSnapshot> _filteredFriends = [];
  List<QueryDocumentSnapshot> _friendRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriendsAndRequests();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _fetchFriendsAndRequests() {
    setState(() {
      isLoading = true;
    });

    // Real-time listener for friend requests
    _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((requestsSnapshot) {
      setState(() {
        _friendRequests = requestsSnapshot.docs;
      });
    });

    setState(() {
      isLoading = false;
    });
  }

  Uint8List? _decodeProfilePicture(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding base64 string: $e');
      return null;
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Friend'),
          content: TextField(
            controller: _manualPhoneController,
            decoration: InputDecoration(
              labelText: 'Enter Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String phoneNumber = _manualPhoneController.text.trim();
                if (phoneNumber.isNotEmpty) {
                  await _sendFriendRequest(phoneNumber);
                  _manualPhoneController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number cannot be empty.')),
                  );
                }
              },
              child: Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFriendRequest(String phoneNumber) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found with that phone number.')),
        );
        return;
      }

      String receiverId = userSnapshot.docs.first.id;

      DocumentSnapshot currentUserSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      String senderName = currentUserSnapshot['fullName'] ?? 'No Name';
      String senderProfilePicture = currentUserSnapshot['profilePicture'] ?? '';

      await _firestore.collection('friendRequests').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'senderName': senderName,
        'senderProfilePicture': senderProfilePicture,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent.')),
      );
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send friend request.')),
      );
    }
  }

  Future<void> _acceptFriendRequest(String requestId, String senderId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
      });

      DocumentSnapshot senderSnapshot = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      String senderName = senderSnapshot['fullName'] ?? 'No Name';
      String senderProfilePicture = senderSnapshot['profilePicture'] ?? '';

      DocumentSnapshot receiverSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      String receiverName = receiverSnapshot['fullName'] ?? 'No Name';
      String receiverProfilePicture = receiverSnapshot['profilePicture'] ?? '';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(senderId)
          .set({
        'friendId': senderId,
        'fullName': senderName,
        'profilePicture': senderProfilePicture,
      });

      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUserId)
          .set({
        'friendId': currentUserId,
        'fullName': receiverName,
        'profilePicture': receiverProfilePicture,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted.')),
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept friend request.')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request rejected.')),
      );
    } catch (e) {
      print('Error rejecting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject friend request.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.lightBlue[50], // Set light blue background
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventListPage()),
                  );
                },
                icon: Icon(Icons.event, size: 24),
                label: Text("Create Your Own Event/List"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Search Friends',
                  hintText: 'Enter a friend\'s name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.indigo),
                ),
              ),
            ),
            if (_friendRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  elevation: 8,
                  child: ExpansionTile(
                    iconColor: Colors.indigo,
                    collapsedIconColor: Colors.teal,
                    title: Text(
                      'Friend Requests (${_friendRequests.length})',
                      style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                    children: _friendRequests.map((request) {
                      final data = request.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['senderProfilePicture'] != ''
                              ? MemoryImage(_decodeProfilePicture(data['senderProfilePicture'])!)
                              : null,
                          child: data['senderProfilePicture'] == null
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                          backgroundColor: Colors.teal,
                        ),
                        title: Text(data['senderName'] ?? 'Unknown User'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptFriendRequest(request.id, data['senderId']),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectFriendRequest(request.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(currentUserId)
                    .collection('friends')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Colors.indigo));
                  }

                  List<String> friendIds = snapshot.data!.docs.map((doc) => doc.id).toList();

                  if (friendIds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off, size: 80, color: Colors.blueGrey),
                          SizedBox(height: 10),
                          Text('No friends found.',
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                        ],
                      ),
                    );
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: friendIds)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: Colors.indigo));
                      }

                      final friendsData = userSnapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        final friendName = data?['fullName']?.toLowerCase() ?? '';
                        final searchQuery = _searchController.text.toLowerCase();
                        return friendName.contains(searchQuery);
                      }).toList();

                      if (friendsData.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80, color: Colors.blueGrey),
                              SizedBox(height: 10),
                              Text('No friends match your search.',
                                  style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: friendsData.length,
                        itemBuilder: (context, index) {
                          final data = friendsData[index].data() as Map<String, dynamic>? ?? {};

                          String friendName = data['fullName'] ?? 'No Name';
                          String profilePicture = data['profilePicture'] ?? '';
                          int upcomingEvents = data['upcomingEvent']?.toInt() ?? 0;

                          Uint8List? profilePictureBytes = profilePicture.isNotEmpty
                              ? _decodeProfilePicture(profilePicture)
                              : null;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            elevation: 6,
                            color: Colors.white.withOpacity(0.95),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profilePictureBytes != null
                                    ? MemoryImage(profilePictureBytes)
                                    : null,
                                child: profilePictureBytes == null
                                    ? Icon(Icons.person, color: Colors.white)
                                    : null,
                                backgroundColor: Colors.teal,
                              ),
                              title: Text(
                                friendName,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo),
                              ),
                              subtitle: Text('Upcoming Events: $upcomingEvents'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsGiftListPage(
                                      friendId: friendsData[index].id,
                                      friendName: friendName,
                                      friendProfilePicture: profilePicture,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }





}
