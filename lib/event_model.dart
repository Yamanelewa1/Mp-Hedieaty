import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package

class Event {
  final String id;
  final String name;
  final String category;
  final DateTime date;
  final String status;  // "upcoming", "current", or "past"

  Event({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.status,
  });

  // Factory method to create Event from Firestore DocumentSnapshot
  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Check for null or invalid date and handle it gracefully
    Timestamp? timestamp = data['date'];
    DateTime eventDate = timestamp?.toDate() ?? DateTime.now(); // Default to current time if null

    return Event(
      id: documentId,
      name: data['name'] ?? 'Unnamed Event',  // Default if name is null
      category: data['category'] ?? 'Uncategorized',  // Default if category is null
      date: eventDate,
      status: data['status'] ?? 'upcoming',  // Default status is 'upcoming'
    );
  }

  // Method to determine the event status based on the current date
  static String getStatus(DateTime eventDate) {
    final now = DateTime.now();
    if (eventDate.isBefore(now)) {
      return 'past';
    } else if (eventDate.isAtSameMomentAs(now)) {
      return 'current';
    } else {
      return 'upcoming';
    }
  }

  // A method to update the event status based on its date.
  String updateStatus() {
    return getStatus(date);
  }

  // Optionally: You can add a method to display a formatted date string (for UI purposes)
  String getFormattedDate() {
    return '${date.month}/${date.day}/${date.year}';
  }
}
