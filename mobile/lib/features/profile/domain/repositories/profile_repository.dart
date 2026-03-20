import '../models/user_profile.dart';

abstract class IProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<void> updateProfile(UserProfile profile);
}
