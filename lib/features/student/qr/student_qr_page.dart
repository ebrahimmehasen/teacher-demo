import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../services/qr_token_service.dart';
import '../../../services/screen_protection_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';

/// Rule 7: a QR token that rotates every 30 seconds, protected from screenshots.
class StudentQrPage extends ConsumerStatefulWidget {
  const StudentQrPage({super.key});

  @override
  ConsumerState<StudentQrPage> createState() => _StudentQrPageState();
}

class _StudentQrPageState extends ConsumerState<StudentQrPage> {
  Timer? _timer;
  var _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    ScreenProtection.enable();
    _now = ref.read(clockProvider)();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = ref.read(clockProvider)());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ScreenProtection.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final tenantId = session?.tenantId;
    if (session == null || tenantId == null) {
      return const EmptyState(
        icon: Icons.qr_code_2_outlined,
        title: 'لا يوجد مدرس مرتبط بعد',
        message: 'اطلب من المساعد إضافتك لمجموعة أولاً.',
      );
    }

    final qr = ref.watch(qrTokenServiceProvider);
    final token = qr.generate(tenantId: tenantId, studentId: session.user.id, now: _now);
    final remaining = qr.remaining(_now);
    final fraction = remaining.inMilliseconds / (qr.windowSeconds * 1000);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اعرض هذا الكود على المساعد لتسجيل حضورك',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: fraction.clamp(0, 1),
                      strokeWidth: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: token,
                      version: QrVersions.auto,
                      size: 200,
                      semanticsLabel: 'كود حضور الطالب',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'يتجدد الكود تلقائياً خلال ${remaining.inSeconds} ثانية',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
