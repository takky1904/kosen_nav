import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<String> _kosenOptions = <String>[
    '長野高専',
    '東京高専',
    '沼津高専',
    '鈴鹿高専',
    '明石高専',
  ];

  static const List<int> _gradeOptions = <int>[1, 2, 3, 4, 5];

  static const List<String> _courseOptions = <String>[
    '情報工学科',
    '機械工学科',
    '電気電子工学科',
    '物質工学科',
    '建築学科',
  ];

  String? _selectedKosen;
  int? _selectedGrade;
  String? _selectedCourse;

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final tt = Theme.of(context).textTheme;

    if (!_isInitialized) {
      profileAsync.whenData((user) {
        _selectedKosen = user.kosenName;
        _selectedGrade = user.grade;
        _selectedCourse = user.courseId;
        _isInitialized = true;
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        leading: const MenuToggleButton(),
        title: Text('プロフィール設定', style: tt.headlineLarge),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('所属情報', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text('シラバス取得に使う所属情報を設定します。', style: tt.bodyMedium),
              const SizedBox(height: 20),
              _DropdownField<String>(
                label: '高専名',
                hintText: '高専を選択',
                value: _selectedKosen,
                items: _kosenOptions,
                onChanged: (value) => setState(() => _selectedKosen = value),
              ),
              const SizedBox(height: 16),
              _DropdownField<int>(
                label: '学年',
                hintText: '学年を選択',
                value: _selectedGrade,
                items: _gradeOptions,
                itemLabelBuilder: (grade) => '$grade年',
                onChanged: (value) => setState(() => _selectedGrade = value),
              ),
              const SizedBox(height: 16),
              _DropdownField<String>(
                label: 'コース',
                hintText: 'コースを選択',
                value: _selectedCourse,
                items: _courseOptions,
                onChanged: (value) => setState(() => _selectedCourse = value),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canSave ? _saveProfile : null,
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave {
    return _selectedKosen != null &&
        _selectedGrade != null &&
        _selectedCourse != null;
  }

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_canSave) {
      messenger.showSnackBar(
        const SnackBar(content: Text('高専名・学年・コースをすべて選択してください。')),
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

    if (!mounted) return;

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
