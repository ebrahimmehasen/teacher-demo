import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/group_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import 'grade_form_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(currentTenantProvider),
      builder: (tenant) => tenant == null
          ? const SizedBox.shrink()
          : PageContainer(
              maxWidth: 900,
              children: [
                _GradesSection(tenantId: tenant.id),
                const SizedBox(height: 16),
                const _PeriodsSection(),
                const SizedBox(height: 16),
                _TenantSettingsForm(key: ValueKey(tenant.settings), tenant: tenant),
              ],
            ),
    );
  }
}

class _GradesSection extends ConsumerWidget {
  const _GradesSection({required this.tenantId});
  final String tenantId;

  Future<void> _edit(BuildContext context, WidgetRef ref, [Grade? grade]) async {
    final result = await showGradeFormDialog(context, tenantId: tenantId, grade: grade);
    if (result == null) return;
    final repo = ref.read(gradeRepositoryProvider);
    await (grade == null ? repo.add(result) : repo.update(result));
    if (context.mounted) showSuccessSnack(context, 'تم حفظ الصف');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Grade grade) async {
    final groups = ref.read(groupsProvider).asData?.value ?? const [];
    if (groups.any((g) => g.gradeId == grade.id)) {
      showErrorSnack(context, 'لا يمكن حذف صف له مجموعات، احذف المجموعات أولاً');
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الصف',
      message: 'هل تريد حذف "${grade.name}"؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(gradeRepositoryProvider).delete(grade.tenantId, grade.id);
    if (context.mounted) showSuccessSnack(context, 'تم حذف الصف');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesProvider);
    return SectionCard(
      title: 'الصفوف الدراسية',
      subtitle: 'السعر وموعد الاستحقاق والسعة الافتراضية لكل صف',
      trailing: TextButton.icon(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة صف'),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: AsyncValueView(
        value: grades,
        loading: const LinearProgressIndicator(),
        builder: (list) => list.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد صفوف بعد، أضف أول صف.'),
              )
            : Column(
                children: [
                  for (final grade in list)
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                      title: Text(grade.name),
                      subtitle: Text(
                        '${Money.format(grade.publicPrice)} شهرياً • الاستحقاق يوم ${grade.dueDay}'
                        ' + ${grade.graceDays} أيام سماح • السعة ${grade.defaultCapacity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _edit(context, ref, grade),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _delete(context, ref, grade),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PeriodsSection extends ConsumerWidget {
  const _PeriodsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(periodsProvider).asData?.value;
    final groups = ref.watch(groupsProvider).asData?.value ?? const [];
    if (periods == null) return const SizedBox.shrink();
    final minCount = GroupService.maxUsedPeriod(groups) + 1;

    Future<void> set(int count) =>
        ref.read(groupRepositoryProvider).setPeriods(periods.copyWith(count: count));

    return SectionCard(
      title: 'فترات الجدول',
      subtitle: 'عدد الصفوف في جدول الحصص الأسبوعي',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            tooltip: 'تقليل',
            onPressed: periods.count > (minCount < 1 ? 1 : minCount)
                ? () => set(periods.count - 1)
                : null,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${periods.count}', style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton.outlined(
            tooltip: 'زيادة',
            onPressed: periods.count < 12 ? () => set(periods.count + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      child: Text(
        minCount > 0
            ? 'لا يمكن تقليل العدد عن $minCount لأن هناك مجموعات في الفترة $minCount.'
            : 'يمكنك إضافة حتى 12 فترة.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Late threshold, payment methods & wallet numbers, level weights.
class _TenantSettingsForm extends ConsumerStatefulWidget {
  const _TenantSettingsForm({super.key, required this.tenant});
  final Tenant tenant;

  @override
  ConsumerState<_TenantSettingsForm> createState() => _TenantSettingsFormState();
}

class _TenantSettingsFormState extends ConsumerState<_TenantSettingsForm> {
  static const _walletMethods = [
    PaymentMethod.vodafoneCash,
    PaymentMethod.instaPay,
    PaymentMethod.bankTransfer,
    PaymentMethod.fawry,
  ];

  late TenantSettings _draft = widget.tenant.settings;
  late final _wallets = {
    for (final m in _walletMethods)
      m: TextEditingController(text: widget.tenant.settings.walletNumbers[m] ?? ''),
  };
  var _saving = false;

  @override
  void dispose() {
    for (final c in _wallets.values) {
      c.dispose();
    }
    super.dispose();
  }

  TenantSettings get _withWallets => _draft.copyWith(
    walletNumbers: {
      for (final e in _wallets.entries)
        if (_draft.acceptedPaymentMethods.contains(e.key) && e.value.text.trim().isNotEmpty)
          e.key: e.value.text.trim(),
    },
  );

  bool get _dirty => _withWallets != widget.tenant.settings;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(tenantRepositoryProvider).update(widget.tenant.copyWith(settings: _withWallets));
    if (!mounted) return;
    setState(() => _saving = false);
    showSuccessSnack(context, 'تم حفظ الإعدادات');
  }

  void _toggleMethod(PaymentMethod method, bool selected) {
    final methods = {..._draft.acceptedPaymentMethods};
    selected ? methods.add(method) : methods.remove(method);
    if (methods.isEmpty) return;
    setState(() => _draft = _draft.copyWith(acceptedPaymentMethods: methods));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'الحضور',
          subtitle: 'يُسجَّل الطالب متأخراً إذا حضر بعد بداية الحصة بأكثر من:',
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _draft.lateThresholdMinutes.toDouble(),
                  max: 30,
                  divisions: 30,
                  label: '${_draft.lateThresholdMinutes} دقيقة',
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(lateThresholdMinutes: v.round())),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  '${_draft.lateThresholdMinutes} دقيقة',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'طرق الدفع',
          subtitle: 'الطرق المقبولة والأرقام التي تظهر لأولياء الأمور',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in PaymentMethod.values)
                    FilterChip(
                      label: Text(method.label),
                      selected: _draft.acceptedPaymentMethods.contains(method),
                      onSelected: (v) => _toggleMethod(method, v),
                    ),
                ],
              ),
              for (final method in _walletMethods)
                if (_draft.acceptedPaymentMethods.contains(method))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _wallets[method],
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: switch (method) {
                          PaymentMethod.vodafoneCash => 'رقم فودافون كاش',
                          PaymentMethod.instaPay => 'حساب إنستاباي',
                          PaymentMethod.bankTransfer => 'بيانات الحساب البنكي',
                          _ => 'كود فوري',
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'حساب مستوى الطالب',
          subtitle: 'وزن الحضور مقابل الدرجات في تقرير المستوى',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Slider(
                value: _draft.attendanceWeight.toDouble(),
                max: 100,
                divisions: 20,
                label: '${_draft.attendanceWeight}%',
                onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(
                    attendanceWeight: v.round(),
                    gradesWeight: 100 - v.round(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الحضور ${_draft.attendanceWeight}%', style: theme.textTheme.titleSmall),
                  Text('الدرجات ${_draft.gradesWeight}%', style: theme.textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            onPressed: _dirty && !_saving ? _save : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ الإعدادات'),
          ),
        ),
      ],
    );
  }
}
