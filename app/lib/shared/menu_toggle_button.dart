import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'providers/navigation_providers.dart';

class MenuToggleButton extends ConsumerWidget {
  const MenuToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.menu, color: AppTheme.neonGreen, size: 28),
      onPressed: () => ref.read(isMenuOpenProvider.notifier).open(),
    );
  }
}
