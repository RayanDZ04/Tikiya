import 'api_client.dart';

class OrganizerNeedsService {
  final ApiClient _api;

  OrganizerNeedsService(this._api);

  Future<void> submit({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String instagram,
  }) async {
    await _api.postJson('/orga-needs', body: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'instagram': instagram,
    });
  }
}
