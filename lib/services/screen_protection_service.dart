import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

/// Wraps `screen_protector`: blocks screenshots on Android, blurs on
/// screen-record on iOS. A no-op on web/desktop, where the channel doesn't exist.
abstract final class ScreenProtection {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> enable() async {
    if (!_supported) return;
    try {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (_) {
      // Best-effort: some platforms/emulators don't implement every method.
    }
  }

  static Future<void> disable() async {
    if (!_supported) return;
    try {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    } catch (_) {}
  }
}
