import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/user.dart';
import '../../shared/widgets.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        leading: const MenuToggleButton(),
        title: Text('プロフィール設定', style: tt.headlineLarge),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('所属情報', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text('シラバス取得に使う所属情報を表示しています。', style: tt.bodyMedium),
              const SizedBox(height: 20),
              _ProfileInfoCard(user: user),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _ProfileEditScreen(),
                      ),
                    );
                    // 編集画面から戻った時に表示内容を最新化する。
                    ref.invalidate(userProfileProvider);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('変更する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final cardColor = AppTheme.bgCard.withValues(alpha: 0.88);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '高専名', value: user.kosenName ?? '未設定'),
          const SizedBox(height: 12),
          _InfoRow(
            label: '学年',
            value: user.grade == null ? '未設定' : '${user.grade}年',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'コース', value: user.courseId ?? '未設定'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ProfileEditScreen extends ConsumerStatefulWidget {
  const _ProfileEditScreen();

  @override
  ConsumerState<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<_ProfileEditScreen> {
  static const List<int> _gradeOptions = <int>[1, 2, 3, 4, 5];

  static const Map<String, String> _legacyKosenAlias = <String, String>{
    '長野高専': '長野工業高等専門学校',
    '東京高専': '東京工業高等専門学校',
    '沼津高専': '沼津工業高等専門学校',
    '鈴鹿高専': '鈴鹿工業高等専門学校',
    '明石高専': '明石工業高等専門学校',
  };

  String? _selectedKosen;
  int? _selectedGrade;
  String? _selectedCourse;

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final schoolsAsync = ref.watch(schoolsProvider);
    final schoolOptions = schoolsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String>[],
    );

    if (!_isInitialized) {
      profileAsync.whenData((user) {
        _selectedKosen = _normalizeSavedKosen(user.kosenName);
        _selectedGrade = user.grade;
        _selectedCourse = user.courseId;
        _isInitialized = true;
      });
    }

    final selectedKosenInOptions =
        _selectedKosen != null && schoolOptions.contains(_selectedKosen);

    final departmentsAsync = _selectedKosen == null || _selectedGrade == null
        ? (_isInitialized
              ? const AsyncValue<List<String>>.data(<String>[])
              : const AsyncValue<List<String>>.loading())
        : ref.watch(
            departmentsProvider(
              DepartmentsQuery(
                kosenName: _selectedKosen!,
                grade: _selectedGrade!,
              ),
            ),
          );
    final departmentOptions = departmentsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String>[],
    );
    final selectedCourseInOptions =
        _selectedCourse != null && departmentOptions.contains(_selectedCourse);
    final canSave =
        _selectedKosen != null &&
        _selectedGrade != null &&
        selectedCourseInOptions;
    final tt = Theme.of(context).textTheme;

    if (_selectedCourse != null &&
        departmentOptions.isNotEmpty &&
        !departmentOptions.contains(_selectedCourse)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCourse = null;
        });
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: Text('所属情報の変更', style: tt.headlineLarge)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('所属情報を編集します。', style: tt.bodyMedium),
              const SizedBox(height: 20),
              _DropdownField<String>(
                label: '高専名',
                hintText: schoolOptions.isEmpty ? '高専一覧を取得中' : '高専を選択',
                value: selectedKosenInOptions ? _selectedKosen : null,
                items: schoolOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedKosen = value;
                    _selectedCourse = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              schoolsAsync.when(
                data: (schools) => schools.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '高専一覧が取得できませんでした。時間をおいて再試行してください。',
                          style: TextStyle(
                            color: AppTheme.neonYellow,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '高専一覧の取得に失敗しました: $err',
                    style: const TextStyle(
                      color: AppTheme.neonRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              _DropdownField<int>(
                label: '学年',
                hintText: '学年を選択',
                value: _selectedGrade,
                items: _gradeOptions,
                itemLabelBuilder: (grade) => '$grade年',
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value;
                    _selectedCourse = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _DropdownField<String>(
                label: 'コース',
                hintText: _selectedKosen == null ? '先に高専を選択' : 'コースを選択',
                value: selectedCourseInOptions ? _selectedCourse : null,
                items: departmentOptions,
                onChanged: (value) => setState(() => _selectedCourse = value),
              ),
              if (_selectedKosen != null)
                departmentsAsync.when(
                  data: (departments) => departments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '学科候補が取得できませんでした。時間をおいて再試行してください。',
                            style: TextStyle(
                              color: AppTheme.neonYellow,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '学科候補を取得中...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '学科候補の取得に失敗しました: $err',
                      style: const TextStyle(
                        color: AppTheme.neonRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canSave ? _saveProfile : null,
                  icon: const Icon(Icons.save),
                  label: const Text('保存して戻る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _normalizeSavedKosen(String? value) {
    if (value == null) return null;
    return _legacyKosenAlias[value] ?? value;
  }

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);

    final departments = _selectedKosen == null
        ? const <String>[]
        : (ref
              .read(
                departmentsProvider(
                  DepartmentsQuery(
                    kosenName: _selectedKosen!,
                    grade: _selectedGrade!,
                  ),
                ),
              )
              .maybeWhen(
                data: (value) => value,
                orElse: () => const <String>[],
              ));

    final canSave =
        _selectedKosen != null &&
        _selectedGrade != null &&
        _selectedCourse != null &&
        departments.contains(_selectedCourse);

    if (!canSave) {
      messenger.showSnackBar(
        const SnackBar(content: Text('高専名・学年・コースを正しく選択してください。')),
      );
      return;
    }

    await ref
        .read(userProfileProvider.notifier)
        .updateUserAffiliation(
          _selectedKosen!,
          _selectedGrade!,
          _selectedCourse!,
        );

    ref.invalidate(userProfileProvider);

    if (!mounted) return;

    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('所属情報を保存しました。')));
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabelBuilder,
  });

  final String label;
  final String hintText;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String Function(T value)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: AppTheme.inputDecoration(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hintText),
          isExpanded: true,
          dropdownColor: AppTheme.bgCard,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabelBuilder?.call(item) ?? item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
