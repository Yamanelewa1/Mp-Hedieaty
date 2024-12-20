class Event {
  String id;
  String name;
  String date;
  String createdAt;
  String creatorId;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.createdAt,
    required this.creatorId,
  });

  // Convert Event to a Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'createdAt': createdAt,
      'creatorId': creatorId,
    };
  }

  // Create Event from a Map (from SQLite)
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      createdAt: map['createdAt'],
      creatorId: map['creatorId'],
    );
  }
}
