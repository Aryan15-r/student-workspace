import 'package:flutter/foundation.dart';
import '../../auth/models/user_profile.dart';

/// Simple provider — profile data is owned by AuthProvider.
/// This exists as a placeholder for future profile-specific state
/// (e.g., editing profile, uploading avatar).
class ProfileProvider extends ChangeNotifier {
  UserProfile? _editingProfile;
  final bool   _isSaving = false;

  UserProfile? get editingProfile => _editingProfile;
  bool         get isSaving       => _isSaving;

  void startEditing(UserProfile profile) {
    _editingProfile = profile;
    notifyListeners();
  }

  void cancelEditing() {
    _editingProfile = null;
    notifyListeners();
  }
}
