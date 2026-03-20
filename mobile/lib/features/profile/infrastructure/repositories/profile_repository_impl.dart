import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements IProfileRepository {

  @override
  Future<UserProfile> getProfile(String userId) async {
    try {
      // In a real app, we would call the backend:
      // final response = await http.get(Uri.parse('$_baseUrl/api/profile/$userId'));
      
      // For now, we mock the response to match the backend's mock data structure
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
      
      return UserProfile(
        id: userId,
        name: "John Doe",
        email: "john@example.com",
        planId: "plan_complete_id",
        status: "active",
        profilePictureUrl: "https://ui-avatars.com/api/?name=John+Doe&background=0B6358&color=fff",
      );
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Simulate update
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
