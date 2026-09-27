import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/payment_service.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../shared/students/student_rows.dart';

/// Records a payment for [row]'s student; shows their payment history below.
class PaymentForm extends ConsumerStatefulWidget {
  const PaymentForm({super.key, required this.row, this.onSaved});

  final StudentRow row;
  final VoidCallback? onSaved;

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late String _month = AppDates.monthKey(ref.read(clockProvider)());
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  var _method = PaymentMethod.cash;
  var _saving = false;
  String? _prefilledFor;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  double _paidFor(List<Payment> payments) =>
      PaymentStatusService.paidAmount(payments, widget.row.student.id, _month);

  void _prefill(List<Payment> payments) {
    final key = '${widget.row.student.id}|$_month';
    if (_prefilledFor == key) return;
    _prefilledFor = key;
    final remaining = widget.row.billing.price - _paidFor(payments);
    _amount.text = remaining > 0 ? remaining.toStringAsFixed(0) : '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(sessionProvider)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(paymentServiceProvider)
          .record(
            tenantId: session.tenantId!,
            student: widget.row.student,
            month: _month,
            amount: double.parse(_amount.text),
            method: _method,
            referenceNumber: _reference.text,
            note: _note.text,
            recordedBy: session.user.id,
            now: ref.read(clockProvider)(),
          );
      if (!mounted) return;
      showSuccessSnack(
        context,
        'تم تسجيل ${Money.format(double.parse(_amount.text))} لـ ${widget.row.student.name}',
      );
      _reference.clear();
      _note.clear();
      _prefilledFor = null;
      widget.onSaved?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    final payments = ref.watch(paymentsProvider).asData?.value ?? const <Payment>[];
    final accepted = tenant?.settings.acceptedPaymentMethods ?? {PaymentMethod.cash};
    if (!accepted.contains(_method)) _method = accepted.first;
    _prefill(payments);

    final row = widget.row;
    final history = payments.where((p) => p.studentId == row.student.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paid = _paidFor(payments);
    final months = PaymentService.selectableMonths(ref.read(clockProvider)());

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 24, child: Text(row.student.name.characters.first)),
            title: Text(row.student.name, style: theme.textTheme.titleMedium),
            subtitle: Text('${row.grade.name} – ${GroupLabels.name(row.group.number)}'),
            trailing: StatusChip.payment(row.billing.status),
          ),
          const SizedBox(height: 8),
          Text(
            row.enrollment.isExempt
                ? 'الطالب معفى من الاشتراك'
                : 'الاشتراك الشهري: ${Money.format(row.billing.price)}'
                      '${row.enrollment.discountPercent > 0 ? ' (بعد خصم ${row.enrollment.discountPercent}%)' : ''}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _month,
            decoration: const InputDecoration(labelText: 'عن شهر'),
            items: [
              for (final m in months)
                DropdownMenuItem(
                  value: m,
                  child: Text(AppDates.monthYear(AppDates.parseMonthKey(m))),
                ),
            ],
            onChanged: (v) => setState(() => _month = v ?? _month),
          ),
          if (paid > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'مدفوع عن هذا الشهر: ${Money.format(paid)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: toneColor(context, StatusTone.success),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ج.م'),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return (n == null || n <= 0) ? 'أدخل مبلغاً صحيحاً' : null;
            },
          ),
          const SizedBox(height: 12),
          Text('طريقة الدفع', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in PaymentMethod.values.where(accepted.contains))
                ChoiceChip(
                  label: Text(m.label),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          if (PaymentService.requiresReference(_method)) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _reference,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم العملية / المرجع'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم العملية مطلوب' : null,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payments_outlined),
            label: const Text('تسجيل الدفع'),
          ),
          const SizedBox(height: 24),
          Text('سجل المدفوعات', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Text('لا توجد مدفوعات مسجلة', style: theme.textTheme.bodySmall)
          else
            for (final p in history.take(8))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  '${Money.format(p.amount)} – ${AppDates.monthYear(AppDates.parseMonthKey(p.month))}',
                ),
                subtitle: Text(
                  '${p.method.label}${p.referenceNumber == null ? '' : ' • ${p.referenceNumber}'}'
                  ' • ${AppDates.short(p.createdAt)}',
                ),
              ),
        ],
      ),
    );
  }
}
