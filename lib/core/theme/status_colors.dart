import 'package:flutter/material.dart';

/// Semantic colors for attendance / payment status chips.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.neutral,
  });

  static const light = StatusColors(
    success: Color(0xFF1E8E3E),
    warning: Color(0xFFB26A00),
    info: Color(0xFF1A73E8),
    danger: Color(0xFFD93025),
    neutral: Color(0xFF6B7280),
  );

  static const dark = StatusColors(
    success: Color(0xFF6DD58C),
    warning: Color(0xFFF6B94D),
    info: Color(0xFF8AB4F8),
    danger: Color(0xFFF28B82),
    neutral: Color(0xFF9CA3AF),
  );

  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final Color neutral;

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? neutral,
  }) => StatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    danger: danger ?? this.danger,
    neutral: neutral ?? this.neutral,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}
