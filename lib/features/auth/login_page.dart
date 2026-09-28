import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/demo_accounts.dart';
import '../../core/router/route_guard.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../services/session_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signIn(phone: _phone.text, password: _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(DemoAccount account) {
    setState(() {
      _phone.text = account.phone;
      _password.text = account.password;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.school_rounded, size: 40, color: scheme.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'منصة المدرس',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'إدارة السنتر والطلاب وأولياء الأمور في مكان واحد',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'رقم الموبايل',
                                prefixIcon: Icon(Icons.phone_iphone),
                              ),
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              textDirection: TextDirection.ltr,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'إظهار' : 'إخفاء',
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: Validators.password,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: scheme.error)),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : const Text('تسجيل الدخول'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'دخول سريع للعرض التجريبي',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كلمة المرور لكل الحسابات: ${DemoAccounts.password}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final account in DemoAccounts.all)
                        ActionChip(
                          avatar: Icon(_roleIcon(account.role), size: 18),
                          label: Text(account.label),
                          onPressed: _loading ? null : () => _fill(account),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _loading ? null : () => context.push(parentSignUpPath),
                    child: const Text('ولي أمر جديد؟ سجّل حساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.teacher => Icons.person_outline,
    UserRole.assistant => Icons.badge_outlined,
    UserRole.student => Icons.backpack_outlined,
    UserRole.parent => Icons.family_restroom,
    UserRole.platformAdmin => Icons.admin_panel_settings_outlined,
  };
}
