import '../models/event.dart';
import 'api_client.dart';

class EventsService {
  final ApiClient _api;

  EventsService(this._api);

  Future<List<PublicEvent>> listPublicEvents() async {
    final json = await _api.getJson('/events');

    final dynamic data;
    if (json is List) {
      data = json;
    } else if (json is Map<String, dynamic>) {
      data = json['data'] ?? json['events'] ?? json['items'] ?? const [];
    } else {
      data = const [];
    }

    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => PublicEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
