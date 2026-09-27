import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/attendance_service.dart';
import '../../../services/qr_token_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../shared/students/student_picker_dialog.dart';
import 'scan_result_card.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  String? _groupId;
  ScanOutcome? _outcome;
  final _recent = <ScanRecorded>[];
  var _busy = false;
  var _undoing = false;
  String? _lastRaw;
  DateTime? _lastRawAt;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Group? _selectedGroup(List<Group> groups) {
    final now = ref.read(clockProvider)();
    _groupId ??=
        GoRouterState.of(context).uri.queryParameters['group'] ??
        AttendanceRules.currentGroup(groups, now)?.id ??
        groups.firstOrNull?.id;
    return groups.where((g) => g.id == _groupId).firstOrNull;
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    final now = DateTime.now();
    // The camera reports the same code many times per second.
    if (raw == _lastRaw && _lastRawAt != null && now.difference(_lastRawAt!).inSeconds < 4) return;
    _lastRaw = raw;
    _lastRawAt = now;
    _process(raw);
  }

  Future<void> _process(String raw) async {
    final groups = ref.read(groupsProvider).asData?.value ?? const <Group>[];
    final group = _selectedGroup(groups);
    final session = ref.read(sessionProvider);
    final tenant = ref.read(currentTenantProvider).asData?.value;
    if (_busy || group == null || session == null || tenant == null) return;

    setState(() => _busy = true);
    final recorder = ref.read(attendanceRecorderProvider);
    try {
      final preview = await recorder.check(
        raw: raw,
        tenantId: tenant.id,
        group: group,
        groupLabel: ref.read(groupLabelsProvider)[group.id] ?? '',
        thresholdMinutes: tenant.settings.lateThresholdMinutes,
        now: ref.read(clockProvider)(),
      );
      if (!mounted) return;
      if (preview.isDuplicate) {
        _feedback(success: false);
        setState(() => _outcome = ScanDuplicate(preview));
        return;
      }
      if (preview.isMakeup) {
        final ownGroup = ref.read(groupLabelsProvider)[preview.enrollment.groupId] ?? '';
        final ok = await showConfirmDialog(
          context,
          title: 'حصة تعويض',
          message:
              '${preview.student.name} مسجل في $ownGroup.\n'
              'هل تريد تسجيل حضوره كحصة تعويض في ${preview.groupLabel}؟',
          confirmLabel: 'تسجيل تعويض',
        );
        if (!ok || !mounted) return;
      }
      final record = await recorder.commit(preview, recordedBy: session.user.id);
      if (!mounted) return;
      _feedback(success: true);
      final outcome = ScanRecorded(preview, record);
      setState(() {
        _outcome = outcome;
        _recent.insert(0, outcome);
      });
    } on ScanRejected catch (e) {
      if (!mounted) return;
      _feedback(success: false);
      setState(() => _outcome = ScanFailed(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _feedback({required bool success}) {
    if (success) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _undo() async {
    final outcome = _outcome;
    if (outcome is! ScanRecorded) return;
    setState(() => _undoing = true);
    await ref.read(attendanceRecorderProvider).undo(outcome.record);
    if (!mounted) return;
    final undone = ScanRecorded(outcome.preview, outcome.record, undone: true);
    setState(() {
      _undoing = false;
      _outcome = undone;
      _recent.remove(outcome);
    });
  }

  /// For demos without a camera: signs a fresh token for the chosen student.
  Future<void> _demoScan() async {
    final students =
        (ref.read(tenantStudentsProvider).asData?.value ?? const <String, User>{}).values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final enrollments = ref.read(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final labels = ref.read(groupLabelsProvider);
    final student = await showStudentPicker(
      context,
      students: students,
      title: 'مسح تجريبي بدون كاميرا',
      subtitles: {for (final e in enrollments) e.studentId: labels[e.groupId] ?? ''},
    );
    final tenantId = ref.read(sessionProvider)?.tenantId;
    if (student == null || tenantId == null) return;
    final token = ref
        .read(qrTokenServiceProvider)
        .generate(tenantId: tenantId, studentId: student.id, now: ref.read(clockProvider)());
    await _process(token);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final labels = ref.watch(groupLabelsProvider);
    if (groups.isEmpty) {
      return const EmptyState(icon: Icons.groups_outlined, title: 'لا توجد مجموعات بعد');
    }
    final group = _selectedGroup(groups);
    final now = ref.watch(clockProvider)();
    final session = group == null ? null : AttendanceRules.sessionOn(group, now);

    final controls = Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterDropdown<String>(
          label: 'المجموعة الحالية',
          width: 280,
          allLabel: null,
          value: _groupId,
          items: labels,
          onChanged: (v) => setState(() => _groupId = v),
        ),
        Text(
          session == null
              ? 'لا توجد حصة لهذه المجموعة اليوم'
              : 'حصة اليوم ${AppDates.clock(session.startTime)} – ${AppDates.clock(session.endTime)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton.icon(
          onPressed: _busy ? null : _demoScan,
          icon: const Icon(Icons.touch_app_outlined),
          label: const Text('مسح تجريبي'),
        ),
      ],
    );

    final camera = Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _camera,
              onDetect: _onDetect,
              errorBuilder: (context, error) => const EmptyState(
                icon: Icons.videocam_off_outlined,
                title: 'الكاميرا غير متاحة',
                message: 'اسمح للتطبيق باستخدام الكاميرا، أو استخدم "مسح تجريبي" للعرض.',
              ),
            ),
            IgnorePointer(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.65,
                  heightFactor: 0.65,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );

    final results = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScanResultCard(outcome: _outcome, onUndo: _undo, undoing: _undoing),
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('آخر المسح (${_recent.length})', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final r in _recent.take(8))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                child: Text(r.preview.student.name.characters.first),
              ),
              title: Text(r.preview.student.name),
              subtitle: Text(AppDates.time(r.preview.scanTime)),
              trailing: StatusChip.attendance(r.preview.status),
            ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            controls,
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: camera,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: results),
                ],
              )
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: camera,
                ),
              ),
              const SizedBox(height: 16),
              results,
            ],
          ],
        );
      },
    );
  }
}
