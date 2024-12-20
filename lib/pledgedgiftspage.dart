import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoadingEvents = true;
  String filterStatus = 'all';
  Map<String, List<Map<String, dynamic>>> eventGifts = {};
  Map<String, String> eventNames = {};

  @override
  void initState() {
    super.initState();
    _fetchAllPledgedGifts();
  }

  Future<void> _fetchAllPledgedGifts() async {
    setState(() {
      isLoadingEvents = true;
    });

    try {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('creatorId', isEqualTo: currentUserId)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        Map<String, List<Map<String, dynamic>>> tempEventGifts = {};
        Map<String, String> tempEventNames = {};

        for (var event in eventSnapshot.docs) {
          final eventId = event.id;
          final eventName = event.get('name') ?? 'Unnamed Event';
          tempEventNames[eventId] = eventName;

          QuerySnapshot giftSnapshot = await _firestore
              .collection('events')
              .doc(eventId)
              .collection('gifts')
              .get();

          tempEventGifts[eventId] = giftSnapshot.docs.map((giftDoc) {
            final giftData = giftDoc.data() as Map<String, dynamic>;
            giftData['giftId'] = giftDoc.id;
            return giftData;
          }).toList();
        }

        setState(() {
          eventGifts = tempEventGifts;
          eventNames = tempEventNames;
        });
      }
    } catch (e) {
      print('Error fetching pledged gifts: $e');
      _showSnackbar('Failed to fetch pledged gifts. Please try again.');
    } finally {
      setState(() {
        isLoadingEvents = false;
      });
    }
  }

  bool _isValidBase64(String? value) {
    if (value == null || value.isEmpty) return false;
    try {
      base64Decode(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildEventGiftsView() {
    return ListView(
      children: eventGifts.entries.map((entry) {
        final eventId = entry.key;
        final eventName = eventNames[eventId] ?? 'Unnamed Event';
        final gifts = entry.value
            .where((gift) => filterStatus == 'all' || gift['status'] == filterStatus)
            .toList();

        if (gifts.isEmpty) {
          return SizedBox();
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.all(10.0),
            title: Text(
              eventName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
                fontSize: 18,
              ),
            ),
            children: gifts.map((gift) => _buildGiftTile(eventId, gift)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGiftTile(String eventId, Map<String, dynamic> gift) {
    return ListTile(
      leading: _buildImageWidget(gift['image']),
      title: Text(
        gift['name'] ?? 'Unnamed Gift',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description: ${gift['description'] ?? 'Unknown'}"),
          Text("Price: \$${gift['price'] ?? 'N/A'}"),
          Text("Status: ${gift['status'] ?? 'N/A'}"),
        ],
      ),
      trailing: gift['status'] == 'available'
          ? PopupMenuButton<String>(
        onSelected: (value) {
          _modifyPledgedGift(eventId, gift['giftId'], value);
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'purchased', child: Text('Mark as Pledged')),
          PopupMenuItem(value: 'Remove', child: Text('Remove Gift')),
        ],
      )
          : Icon(Icons.lock, color: Colors.grey),
    );
  }

  Widget _buildImageWidget(String? base64Image) {
    if (base64Image == null || !_isValidBase64(base64Image)) {
      return Icon(Icons.card_giftcard, size: 50, color: Colors.teal.shade300);
    }

    try {
      Uint8List imageData = base64Decode(base64Image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.memory(
          imageData,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Icon(Icons.card_giftcard, size: 50, color: Colors.teal.shade300);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _modifyPledgedGift(String eventId, String giftId, String action) async {
    try {
      if (action == 'Remove') {
        await _firestore
            .collection('events')
            .doc(eventId)
            .collection('gifts')
            .doc(giftId)
            .delete();
        _showSnackbar('Gift removed successfully!');
      } else if (action == 'purchased') {
        await _firestore
            .collection('events')
            .doc(eventId)
            .collection('gifts')
            .doc(giftId)
            .update({'status': 'pledged'});
        _showSnackbar('Gift marked as pledged!');
      }

      _fetchAllPledgedGifts();
    } catch (e) {
      print('Error modifying gift: $e');
      _showSnackbar('Failed to update gift. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pledged Gifts'),
        backgroundColor: Colors.teal.shade600,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'available', child: Text('Available')),
              PopupMenuItem(value: 'pledged', child: Text('Pledged')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade100, Colors.teal.shade400],
          ),
        ),
        child: isLoadingEvents
            ? Center(child: CircularProgressIndicator(color: Colors.teal.shade900))
            : eventGifts.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard, size: 80, color: Colors.teal.shade300),
              SizedBox(height: 10),
              Text(
                'No pledged gifts found.',
                style: TextStyle(fontSize: 16, color: Colors.teal.shade900),
              ),
            ],
          ),
        )
            : _buildEventGiftsView(),
      ),
    );
  }
}
