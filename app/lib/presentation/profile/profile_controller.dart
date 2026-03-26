import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/user_repository.dart';
import '../../domain/models/user.dart';
import 'departments_api_client.dart';
import 'schools_api_client.dart';

class DepartmentsQuery {
  const DepartmentsQuery({required this.kosenName, required this.grade});

  final String kosenName;
  final int grade;

  @override
  bool operator ==(Object other) {
    return other is DepartmentsQuery &&
        other.kosenName == kosenName &&
        other.grade == grade;
  }

  @override
  int get hashCode => Object.hash(kosenName, grade);
}

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

final departmentsApiClientProvider = Provider<DepartmentsApiClient>(
  (ref) => DepartmentsApiClient(),
);

final schoolsApiClientProvider = Provider<SchoolsApiClient>(
  (ref) => SchoolsApiClient(),
);

final schoolsProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.watch(schoolsApiClientProvider);
  return client.fetchSchools();
});

final departmentsProvider =
    FutureProvider.family<List<String>, DepartmentsQuery>((ref, query) async {
      final client = ref.watch(departmentsApiClientProvider);
      return client.fetchDepartments(query.kosenName, query.grade);
    });
