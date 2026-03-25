import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/user_repository.dart';
import '../../domain/models/user.dart';

class UserProfileNotifier extends AsyncNotifier<User> {
  final UserRepository _repository = UserRepository();

  @override
  Future<User> build() async {
    return _repository.getCurrentUser();
  }

  Future<void> updateUserAffiliation(
    String kosenName,
    int grade,
    String courseId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.updateUserAffiliation(kosenName, grade, courseId),
    );
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, User>(
  UserProfileNotifier.new,
);
