class PublicEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? startsAt;
  final num? price;

  const PublicEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.startsAt,
    this.price,
  });

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['event_id'] ?? '';
    final rawTitle = json['title'] ?? json['name'] ?? json['nom'] ?? '';

    DateTime? startsAt;
    final rawStartsAt = json['starts_at'] ?? json['start_date'] ?? json['date'] ?? json['startsAt'];
    if (rawStartsAt is String && rawStartsAt.isNotEmpty) {
      startsAt = DateTime.tryParse(rawStartsAt);
    }

    num? price;
    final rawPrice = json['price'] ?? json['prix'] ?? json['amount'];
    if (rawPrice is num) price = rawPrice;
    if (rawPrice is String) price = num.tryParse(rawPrice);

    return PublicEvent(
      id: rawId.toString(),
      title: rawTitle.toString(),
      description: (json['description'] ?? json['details'])?.toString(),
      location: (json['location'] ?? json['city'] ?? json['lieu'])?.toString(),
      startsAt: startsAt,
      price: price,
    );
  }
}
