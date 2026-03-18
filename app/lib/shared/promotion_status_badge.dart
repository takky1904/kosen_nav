import 'package:flutter/material.dart';
import '../features/simulation/application/simulation_controller.dart';
import '../core/theme/app_theme.dart';

class PromotionStatusBadge extends StatefulWidget {
  final PromotionStatus status;
  final int failCount;
  final bool compact; // サイドバー用コンパクト表示
  final bool isLarge; // ホーム画面中央用大型表示

  const PromotionStatusBadge({
    required this.status,
    required this.failCount,
    this.compact = false,
    this.isLarge = false,
    super.key,
  });

  @override
  State<PromotionStatusBadge> createState() => _PromotionStatusBadgeState();
}

class _PromotionStatusBadgeState extends State<PromotionStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // 危険な場合のみパルスアニメーション
    if (widget.status == PromotionStatus.danger ||
        widget.status == PromotionStatus.failing) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PromotionStatusBadge old) {
    super.didUpdateWidget(old);
    if (widget.status == PromotionStatus.danger ||
        widget.status == PromotionStatus.failing) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status) {
      case PromotionStatus.passing:     return AppTheme.statusPass;
      case PromotionStatus.conditional: return AppTheme.statusConditional;
      case PromotionStatus.danger:      return AppTheme.statusDanger;
      case PromotionStatus.failing:     return AppTheme.statusFailing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    if (widget.compact) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Opacity(
          opacity: _pulseAnim.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withAlpha(180), width: 1),
          ),
          child: Text(
            '${widget.status.emoji} ${widget.status.label}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    if (widget.isLarge) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: widget.status == PromotionStatus.danger || widget.status == PromotionStatus.failing
              ? _pulseAnim.value
              : 1.0,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.status.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    widget.status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              if (widget.failCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '現在 ${widget.failCount} 科目が不可の状態です',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.status.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.status.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                if (widget.failCount > 0)
                  Text(
                    '不可 ${widget.failCount}科目',
                    style: TextStyle(
                      color: color.withAlpha(200),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
