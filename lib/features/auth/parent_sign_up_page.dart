import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import '../../services/parent_auth_service.dart';
import '../../services/session_service.dart';

/// Self-service parent sign-up: account details, then link the first child
/// by their code (more children can be added later from "المزيد").
class ParentSignUpPage extends ConsumerStatefulWidget {
  const ParentSignUpPage({super.key});

  @override
  ConsumerState<ParentSignUpPage> createState() => _ParentSignUpPageState();
}

class _ParentSignUpPageState extends ConsumerState<ParentSignUpPage> {
  final _accountFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  var _step = 0;
  var _busy = false;
  String? _error;
  User? _parent;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Signing in only after both steps avoids a mid-flow session change
      // (which the router reacts to) from resetting this page's state.
      final parent = await ref
          .read(parentAuthServiceProvider)
          .signUp(name: _name.text, phone: _phone.text, password: _password.text);
      if (!mounted) return;
      setState(() {
        _parent = parent;
        _step = 1;
      });
    } on ParentAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkChild() async {
    if (!_codeFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final child = await ref
          .read(parentAuthServiceProvider)
          .linkChildByCode(parent: _parent!, code: _code.text);
      await ref
          .read(sessionProvider.notifier)
          .signIn(phone: _phone.text.trim(), password: _password.text);
      await ref.read(sessionProvider.notifier).selectChild(child.id);
      if (mounted) context.go('/parent/home');
    } on ParentAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    await ref
        .read(sessionProvider.notifier)
        .signIn(phone: _phone.text.trim(), password: _password.text);
    if (mounted) context.go('/parent/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('حساب ولي أمر جديد')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _step == 0 ? _accountStep(theme) : _linkChildStep(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountStep(ThemeData theme) {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بيانات الحساب',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => Validators.required(v, field: 'الاسم'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الموبايل',
              prefixIcon: Icon(Icons.phone_iphone),
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: Validators.password,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _createAccount,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('التالي'),
          ),
        ],
      ),
    );
  }

  Widget _linkChildStep(ThemeData theme) {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.family_restroom, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'إضافة طفلك',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'اطلب من ابنك/ابنتك كود الربط من صفحة "الملف الشخصي" في تطبيقه',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _code,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4),
            decoration: const InputDecoration(labelText: 'كود الربط'),
            validator: (v) => Validators.required(v, field: 'كود الربط'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _linkChild,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ربط الطفل'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _skip,
            child: const Text('تخطي الآن، سأضيفه لاحقاً'),
          ),
        ],
      ),
    );
  }
}
