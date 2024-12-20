import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftDetailsPage extends StatefulWidget {
  final String eventId;
  final String? giftId;

  GiftDetailsPage({
    required this.eventId,
    this.giftId,
  });

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  String description = '';
  String category = '';
  double price = 0.0;
  String status = 'available';
  String? imageBase64;

  bool isPledged = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.giftId != null) {
      _fetchGiftDetails();
    }
  }

  Future<void> _fetchGiftDetails() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot giftDoc = await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('gifts')
          .doc(widget.giftId)
          .get();

      if (giftDoc.exists) {
        final data = giftDoc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'] ?? '';
          description = data['description'] ?? '';
          category = data['category'] ?? '';
          price = data['price']?.toDouble() ?? 0.0;
          status = data['status'] ?? 'available';
          imageBase64 = data['image'];
          isPledged = status == 'pledged';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load gift details.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateGiftStatus(String newStatus) async {
    try {
      await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('gifts')
          .doc(widget.giftId)
          .update({'status': newStatus});

      if (newStatus == 'pledged') {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status.')),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('gifts')
          .doc(widget.giftId)
          .update({
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[50]!, Colors.pink[100]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.giftId == null ? 'Gift Details' : 'Edit Gift',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.pink,
          elevation: 10,
        ),
        body: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 10,
                  shadowColor: Colors.pinkAccent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: imageBase64 != null && imageBase64!.isNotEmpty
                        ? Image.memory(
                      base64Decode(imageBase64!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          'No Image Available',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15.0),
                Text(
                  'Gift Details',
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: TextEditingController(text: name),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.card_giftcard, color: Colors.pink),
                    labelStyle: TextStyle(color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: TextEditingController(text: description),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description, color: Colors.pink),
                    labelStyle: TextStyle(color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: TextEditingController(text: category),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category, color: Colors.pink),
                    labelStyle: TextStyle(color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                  onChanged: (value) => category = value,
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: TextEditingController(text: price.toString()),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money, color: Colors.pink),
                    labelStyle: TextStyle(color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                  price = double.tryParse(value) ?? 0.0,
                ),
                const SizedBox(height: 15.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    DropdownButton<String>(
                      value: status,
                      items: ['available', 'pledged']
                          .map(
                            (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(color: Colors.pink),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: isPledged
                          ? null
                          : (value) async {
                        if (value == 'pledged') {
                          await _updateGiftStatus(value!);
                        } else {
                          setState(() {
                            status = value!;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _saveChanges,
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
