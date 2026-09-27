import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum QrError { malformed, badSignature, expired, otherTenant }

class QrVerification {
  const QrVerification.valid(String this.studentId) : error = null;
  const QrVerification.invalid(QrError this.error) : studentId = null;

  final String? studentId;
  final QrError? error;

  bool get isValid => error == null;
}

/// Rule 7: payload `tenantId|studentId|window` signed with HMAC-SHA256.
/// A window lasts [windowSeconds]; the scanner accepts the current or previous one.
class QrTokenService {
  const QrTokenService({this.secret = _mockSecret, this.windowSeconds = 30});

  /// Mock-only secret. With a real backend the token is issued/verified server side.
  static const _mockSecret = 'teacher-demo-mock-qr-secret';

  final String secret;
  final int windowSeconds;

  int windowAt(DateTime time) => time.millisecondsSinceEpoch ~/ 1000 ~/ windowSeconds;

  /// Time left before the token shown at [now] rotates.
  Duration remaining(DateTime now) {
    final elapsed = now.millisecondsSinceEpoch % (windowSeconds * 1000);
    return Duration(milliseconds: windowSeconds * 1000 - elapsed);
  }

  String generate({required String tenantId, required String studentId, required DateTime now}) {
    final payload = '$tenantId|$studentId|${windowAt(now)}';
    return '$payload|${_sign(payload)}';
  }

  QrVerification verify(String raw, {required String tenantId, required DateTime now}) {
    final parts = raw.trim().split('|');
    if (parts.length != 4 || parts.any((p) => p.isEmpty)) {
      return const QrVerification.invalid(QrError.malformed);
    }
    final [tokenTenant, studentId, windowText, signature] = parts;
    final window = int.tryParse(windowText);
    if (window == null) return const QrVerification.invalid(QrError.malformed);

    final payload = '$tokenTenant|$studentId|$windowText';
    if (!_constantTimeEquals(_sign(payload), signature)) {
      return const QrVerification.invalid(QrError.badSignature);
    }
    if (tokenTenant != tenantId) return const QrVerification.invalid(QrError.otherTenant);

    final current = windowAt(now);
    if (window != current && window != current - 1) {
      return const QrVerification.invalid(QrError.expired);
    }
    return QrVerification.valid(studentId);
  }

  String _sign(String payload) {
    final mac = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    return base64Url.encode(mac.bytes).replaceAll('=', '');
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final qrTokenServiceProvider = Provider((ref) => const QrTokenService());

extension QrErrorMessage on QrError {
  String get message => switch (this) {
    QrError.malformed => 'هذا الكود ليس كود حضور صالح',
    QrError.badSignature => 'الكود غير صحيح أو تم التلاعب به',
    QrError.expired => 'انتهت صلاحية الكود، اطلب من الطالب تحديثه',
    QrError.otherTenant => 'هذا الكود خاص بمدرس آخر',
  };
}
