import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/constants/api_constants.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final String? _token;
  final String _baseUrl = ApiConstants.baseUrl;

  ProfileRepositoryImpl({String? token}) : _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserProfile.fromMap(data, data['id'] ?? '');
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/profile/'),
        headers: _headers,
        body: json.encode(profile.toMap()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
