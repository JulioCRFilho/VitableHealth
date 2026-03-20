import '../models/user_profile.dart';

abstract class IProfileRepository {
  Future<UserProfile> getProfile();
  Future<void> updateProfile(UserProfile profile);
}
