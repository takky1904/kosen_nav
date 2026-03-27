import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/grades/application/grade_controller.dart';
import '../../features/grades/data/course_repository.dart';
import '../../data/network/syllabus_api_client.dart';
import '../../data/sync/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user.dart';
import '../../shared/widgets.dart';
import 'profile_controller.dart';
import 'profile_master_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final schoolsAsync = ref.watch(schoolsProvider);
    final currentUser = profileAsync.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    final departmentsAsync =
        (currentUser?.kosenName == null || currentUser?.grade == null)
        ? const AsyncValue<List<DepartmentOption>>.data(<DepartmentOption>[])
        : ref.watch(
            departmentsProvider(
              DepartmentsQuery(
                kosenId: currentUser!.kosenName!,
                grade: currentUser.grade!,
              ),
            ),
          );

    final kosenDisplay = _resolveKosenDisplayName(
      kosenId: currentUser?.kosenName,
      schools: schoolsAsync.maybeWhen(
        data: (value) => value,
        orElse: () => const <SchoolOption>[],
      ),
    );
    final courseDisplay = _resolveCourseDisplayName(
      courseId: currentUser?.courseId,
      departments: departmentsAsync.maybeWhen(
        data: (value) => value,
        orElse: () => const <DepartmentOption>[],
      ),
    );

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
              Text('マスタデータから取得した所属情報を表示しています。', style: tt.bodyMedium),
              const SizedBox(height: 20),
              _ProfileInfoCard(
                user: user,
                kosenDisplayName: kosenDisplay,
                courseDisplayName: courseDisplay,
              ),
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

  String _resolveKosenDisplayName({
    required String? kosenId,
    required List<SchoolOption> schools,
  }) {
    if (kosenId == null || kosenId.isEmpty) {
      return '未設定';
    }

    for (final school in schools) {
      if (school.kosenId == kosenId) {
        return school.kosenName;
      }
    }
    return kosenId;
  }

  String _resolveCourseDisplayName({
    required String? courseId,
    required List<DepartmentOption> departments,
  }) {
    if (courseId == null || courseId.isEmpty) {
      return '未設定';
    }

    for (final department in departments) {
      if (department.id == courseId) {
        return department.displayName;
      }
    }

    return courseId;
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.user,
    required this.kosenDisplayName,
    required this.courseDisplayName,
  });

  final User user;
  final String kosenDisplayName;
  final String courseDisplayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '高専', value: kosenDisplayName),
          const SizedBox(height: 12),
          _InfoRow(
            label: '学年',
            value: user.grade == null ? '未設定' : '${user.grade}年',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'コース', value: courseDisplayName),
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
  final SyllabusApiClient _syllabusApiClient = SyllabusApiClient();
  final CourseRepository _courseRepository = CourseRepository();
  final SyncService _syncService = SyncService();

  String? _selectedKosenId;
  int? _selectedGrade;
  String? _selectedCourseId;

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final schoolsAsync = ref.watch(schoolsProvider);
    final schoolOptions = schoolsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <SchoolOption>[],
    );

    if (!_isInitialized) {
      profileAsync.whenData((user) {
        _selectedKosenId = user.kosenName;
        _selectedGrade = user.grade;
        _selectedCourseId = user.courseId;
        _isInitialized = true;
      });
    }

    final selectedKosenInOptions =
        _selectedKosenId != null &&
        schoolOptions.any((school) => school.kosenId == _selectedKosenId);

    final departmentsAsync = _selectedKosenId == null || _selectedGrade == null
        ? (_isInitialized
              ? const AsyncValue<List<DepartmentOption>>.data(
                  <DepartmentOption>[],
                )
              : const AsyncValue<List<DepartmentOption>>.loading())
        : ref.watch(
            departmentsProvider(
              DepartmentsQuery(
                kosenId: _selectedKosenId!,
                grade: _selectedGrade!,
              ),
            ),
          );

    final departmentOptions = departmentsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <DepartmentOption>[],
    );

    final selectedCourseInOptions =
        _selectedCourseId != null &&
        departmentOptions.any(
          (department) => department.id == _selectedCourseId,
        );

    final canSave =
        _selectedKosenId != null &&
        _selectedGrade != null &&
        selectedCourseInOptions;

    final tt = Theme.of(context).textTheme;

    if (_selectedCourseId != null &&
        departmentOptions.isNotEmpty &&
        !departmentOptions.any(
          (department) => department.id == _selectedCourseId,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCourseId = null;
        });
      });
    }

    final selectedSchool = selectedKosenInOptions
        ? schoolOptions.firstWhere(
            (school) => school.kosenId == _selectedKosenId,
          )
        : null;

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
              _DropdownField<SchoolOption>(
                label: '高専',
                hintText: schoolOptions.isEmpty ? '高専一覧を取得中' : '高専を選択',
                value: selectedSchool,
                items: schoolOptions,
                itemLabelBuilder: (school) => school.kosenName,
                onChanged: (value) {
                  setState(() {
                    _selectedKosenId = value?.kosenId;
                    _selectedCourseId = null;
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
                    _selectedCourseId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _DropdownField<DepartmentOption>(
                label: 'コース',
                hintText: _selectedKosenId == null ? '先に高専を選択' : 'コースを選択',
                value: selectedCourseInOptions
                    ? departmentOptions.firstWhere(
                        (department) => department.id == _selectedCourseId,
                      )
                    : null,
                items: departmentOptions,
                itemLabelBuilder: (department) => department.displayName,
                onChanged: (value) =>
                    setState(() => _selectedCourseId = value?.id),
              ),
              if (_selectedKosenId != null)
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

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);

    final departments = _selectedKosenId == null || _selectedGrade == null
        ? const <DepartmentOption>[]
        : ref
              .read(
                departmentsProvider(
                  DepartmentsQuery(
                    kosenId: _selectedKosenId!,
                    grade: _selectedGrade!,
                  ),
                ),
              )
              .maybeWhen(
                data: (value) => value,
                orElse: () => const <DepartmentOption>[],
              );

    final canSave =
        _selectedKosenId != null &&
        _selectedGrade != null &&
        _selectedCourseId != null &&
        departments.any((department) => department.id == _selectedCourseId);

    if (!canSave) {
      messenger.showSnackBar(
        const SnackBar(content: Text('高専・学年・コースを正しく選択してください。')),
      );
      return;
    }

    String? syllabusError;
    try {
      final subjects = await _syllabusApiClient.fetchSyllabusSubjects(
        kosenId: _selectedKosenId!,
        grade: _selectedGrade!,
        courseId: _selectedCourseId!,
      );

      if (subjects.isEmpty) {
        syllabusError = 'シラバス科目が0件でした。学校・学年・コースの組み合わせを確認してください。';
      }

      if (syllabusError == null) {
        await ref
            .read(userProfileProvider.notifier)
            .updateUserAffiliation(
              _selectedKosenId!,
              _selectedGrade!,
              _selectedCourseId!,
            );

        await _courseRepository.replaceCoursesFromSyllabus(subjects);
        await _syncService.pushLocalChanges();
        ref.invalidate(gradeNotifierProvider);

        debugPrint(
          '[Syllabus Verify] kosenId=${_selectedKosenId!}, grade=${_selectedGrade!}, courseId=${_selectedCourseId!}, count=${subjects.length}',
        );
        debugPrint(
          '[Syllabus Verify] subjects=${subjects.map((s) => s['name']).toList()}',
        );
      }
    } catch (e) {
      debugPrint('[Syllabus Verify] fetch failed: $e');
      syllabusError = 'シラバス取得に失敗しました: $e';
    }

    if (syllabusError != null) {
      messenger.showSnackBar(SnackBar(content: Text(syllabusError)));
      return;
    }

    ref.invalidate(userProfileProvider);

    if (!mounted) return;

    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('所属情報を保存しました。')));
  }
}

class _DropdownField<T> extends StatefulWidget {
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
  State<_DropdownField<T>> createState() => _DropdownFieldState<T>();
}

class _DropdownFieldState<T> extends State<_DropdownField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _overlayController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _sizeAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  void _toggleOpen() {
    if (widget.items.isEmpty) return;
    if (_isOpen) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _selectItem(T item) {
    widget.onChanged(item);
    _hideOverlay();
  }

  @override
  void didUpdateWidget(covariant _DropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty && _isOpen) {
      _hideOverlay();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;
    final overlay = Overlay.of(context);
    final selectedValue = widget.value;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 72),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  sizeFactor: _sizeAnimation,
                  axisAlignment: -1,
                  child: Container(
                    width: MediaQuery.sizeOf(context).width - 40,
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppTheme.border.withAlpha(120),
                      ),
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final label =
                            widget.itemLabelBuilder?.call(item) ??
                            item.toString();
                        final selected = selectedValue == item;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectItem(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: selected
                                            ? AppTheme.neonGreen
                                            : AppTheme.textPrimary,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppTheme.neonGreen,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    _overlayController.forward(from: 0);
    if (mounted) {
      setState(() => _isOpen = true);
    }
  }

  Future<void> _hideOverlay() async {
    if (_overlayEntry == null) return;
    await _overlayController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.value != null
        ? widget.itemLabelBuilder?.call(widget.value as T) ??
              widget.value.toString()
        : null;
    final isEnabled = widget.items.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleOpen,
        child: InputDecorator(
          decoration: AppTheme.inputDecoration(widget.label),
          child: Container(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayValue ?? widget.hintText,
                    style: TextStyle(
                      color: displayValue != null
                          ? AppTheme.textPrimary
                          : (isEnabled
                                ? AppTheme.textSecondary
                                : AppTheme.textSecondary.withAlpha(140)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.arrow_drop_down,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
