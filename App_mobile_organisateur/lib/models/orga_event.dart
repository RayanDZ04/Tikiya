class OrgaEvent {
  final String id;
  final String organizerId;
  final String title;
  final String? description;
  final DateTime date;
  final String city;
  final String venue;
  final String category;
  final double price;
  final int maxParticipants;
  final String? location;

  const OrgaEvent({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.date,
    required this.city,
    required this.venue,
    required this.category,
    required this.price,
    required this.maxParticipants,
    required this.location,
  });

  static OrgaEvent fromJson(Map<String, dynamic> json) {
    // Backend date is YYYY-MM-DD
    final dateStr = (json['date'] ?? '').toString();
    final parsedDate = DateTime.tryParse(dateStr);
    return OrgaEvent(
      id: (json['id'] ?? '').toString(),
      organizerId: (json['organizer_id'] ?? json['organizerId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      date: parsedDate ?? DateTime.now(),
      city: (json['city'] ?? '').toString(),
      venue: (json['venue'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse((json['price'] ?? '0').toString()) ?? 0,
      maxParticipants: (json['max_participants'] is num)
          ? (json['max_participants'] as num).toInt()
          : int.tryParse((json['max_participants'] ?? '0').toString()) ?? 0,
      location: json['location']?.toString(),
    );
  }
}

class OrgaEventDraft {
  final String title;
  final String? description;
  final DateTime date;
  final String city;
  final String venue;
  final String category;
  final double price;
  final int maxParticipants;
  final String? location;

  const OrgaEventDraft({
    required this.title,
    required this.description,
    required this.date,
    required this.city,
    required this.venue,
    required this.category,
    required this.price,
    required this.maxParticipants,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return {
      'title': title,
      if (description != null) 'description': description,
      'date': '$yyyy-$mm-$dd',
      'city': city,
      'venue': venue,
      'category': category,
      'price': price,
      'max_participants': maxParticipants,
      if (location != null) 'location': location,
    };
  }
}
