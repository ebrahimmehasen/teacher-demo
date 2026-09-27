abstract final class Validators {
  static final _egyptianMobile = RegExp(r'^01[0125]\d{8}$');

  static String? required(String? value, {String field = 'هذا الحقل'}) =>
      (value == null || value.trim().isEmpty) ? '$field مطلوب' : null;

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'رقم الموبايل مطلوب';
    if (!_egyptianMobile.hasMatch(v)) return 'رقم موبايل غير صحيح (11 رقم يبدأ بـ 01)';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'القيمة'}) {
    final n = num.tryParse(value?.trim() ?? '');
    if (n == null) return '$field مطلوبة';
    if (n <= 0) return '$field يجب أن تكون أكبر من صفر';
    return null;
  }
}
