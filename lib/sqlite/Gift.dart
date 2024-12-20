class Gift {
  String id;
  String name;
  String description;
  String category;
  double price;
  String status; // Example: "pledged" or "available"
  String image; // Base64-encoded image string
  String eventId;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    required this.image,
    required this.eventId,
  });

  // Convert Gift to a Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'image': image,
      'eventId': eventId,
    };
  }

  // Create Gift from a Map (from SQLite)
  factory Gift.fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      status: map['status'],
      image: map['image'],
      eventId: map['eventId'],
    );
  }
}
