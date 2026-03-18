import 'package:flutter_riverpod/flutter_riverpod.dart';

/// メニューの開閉状態を管理するNotifier
class MenuOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

final isMenuOpenProvider = NotifierProvider<MenuOpenNotifier, bool>(MenuOpenNotifier.new);
