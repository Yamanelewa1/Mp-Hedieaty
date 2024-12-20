import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'GiftDetailsPage.dart';

class GiftListPage extends StatefulWidget {
  final String eventId;
  final String eventName;

  GiftListPage({
    required this.eventId,
    required this.eventName,
  });

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  String? creatorId;
  List<QueryDocumentSnapshot> _gifts = [];
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImage;

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
      await _fetchEventDetails();
      await _fetchGifts();
    }
  }

  Future<void> _fetchEventDetails() async {
    try {
      DocumentSnapshot eventDoc =
      await _firestore.collection('events').doc(widget.eventId).get();

      if (eventDoc.exists) {
        setState(() {
          creatorId = eventDoc['creatorId'];
        });
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  Future<void> _fetchGifts() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot giftSnapshot = await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('gifts')
          .get();

      setState(() {
        _gifts = giftSnapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching gifts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch gifts. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes, {int width = 200}) async {
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final resizedImage = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return resizedImage!.buffer.asUint8List();
  }

  Future<void> _addGift() async {
    String name = '';
    String description = '';
    String category = '';
    double price = 0.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Description'),
                      onChanged: (value) => description = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Category'),
                      onChanged: (value) => category = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                      price = double.tryParse(value) ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          final compressedImage = await _compressImage(bytes);
                          setState(() {
                            _selectedImage = compressedImage;
                          });
                        }
                      },
                      child: Text('Upload Image'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (name.isNotEmpty &&
                            description.isNotEmpty &&
                            _selectedImage != null) {
                          String imageBase64 = base64Encode(_selectedImage!);
                          await _firestore
                              .collection('events')
                              .doc(widget.eventId)
                              .collection('gifts')
                              .add({
                            'name': name,
                            'description': description,
                            'category': category,
                            'price': price,
                            'status': 'available',
                            'image': imageBase64,
                          });
                          Navigator.pop(context);
                          _fetchGifts();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Please provide all required information.')),
                          );
                        }
                      },
                      child: Text('Add Gift'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftCard(QueryDocumentSnapshot gift) {
    final status = gift['status'] ?? 'available';
    final isPledged = status == 'pledged';
    final imageBase64 = gift['image'];

    Widget imageWidget;
    if (imageBase64 != null && _isValidBase64(imageBase64)) {
      try {
        imageWidget = Image.memory(
          base64Decode(imageBase64),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120, // Adjusted height
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        imageWidget = _buildPlaceholderImage();
      }
    } else {
      imageWidget = _buildPlaceholderImage();
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: isPledged ? Colors.red.shade300 : Colors.green.shade300,
      color: isPledged ? Colors.red.shade50 : Colors.green.shade50,
      child: InkWell(
        onTap: () => !isPledged
            ? Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GiftDetailsPage(
              eventId: widget.eventId,
              giftId: gift.id,
            ),
          ),
        )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: imageWidget,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift['name'] ?? 'Unnamed Gift',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    gift['description'] ?? 'No description available.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPledged
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      if (isPledged)
                        Icon(
                          Icons.check_circle,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      width: double.infinity,
      height: 120,
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
    );
  }

  bool _isValidBase64(String str) {
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    bool isCreator = currentUserId == creatorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.eventName} Gifts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        actions: isCreator
            ? [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _addGift,
          ),
        ]
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade200, Colors.indigo.shade400],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : _gifts.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard, size: 80, color: Colors.white70),
              SizedBox(height: 10),
              Text(
                'No gifts found.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _gifts.length,
            itemBuilder: (context, index) {
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: _buildGiftCard(_gifts[index]),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
