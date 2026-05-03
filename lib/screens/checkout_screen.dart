import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'card';
  bool _busy = false;

  Future<void> _confirm() async {
    final isEn = context.read<AppState>().locale.languageCode == 'en';
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await context.read<AppState>().purchaseCourse(widget.courseId);
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEn ? 'Purchase confirmed' : 'تم تأكيد الشراء')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final course = app.courseById(widget.courseId);
    final theme = Theme.of(context);

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isEn ? 'Checkout' : 'الدفع')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEn ? 'Back' : 'رجوع'),
          ),
        ),
      );
    }

    final tax = course.price * 0.07;
    final total = course.price + tax;

    return Scaffold(
      appBar: AppBar(title: Text(isEn ? 'Checkout' : 'الدفع')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(isEn ? 'Order summary' : 'ملخص الطلب', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  course.thumbnailUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school),
                ),
              ),
              title: Text(course.title),
              subtitle: Text(course.category),
              trailing: Text('\$${course.price.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 20),
          Text(isEn ? 'Payment method' : 'طريقة الدفع', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'card',
            groupValue: _method,
            onChanged: _busy ? null : (v) => setState(() => _method = v!),
            title: Text(isEn ? 'Card ending •••• 4242' : 'بطاقة تنتهي بـ •••• 4242'),
            subtitle: Text(isEn ? 'Secured processing' : 'معالجة آمنة'),
          ),
          RadioListTile<String>(
            value: 'wallet',
            groupValue: _method,
            onChanged: _busy ? null : (v) => setState(() => _method = v!),
            title: Text(isEn ? 'CourseLab Wallet' : 'محفظة كورس لاب'),
            subtitle: Text(isEn ? 'Available balance' : 'الرصيد المتاح'),
          ),
          const Divider(height: 32),
          _line(isEn ? 'Subtotal' : 'المجموع الفرعي', course.price),
          _line(isEn ? 'Estimated tax' : 'الضريبة المقدرة', tax),
          const SizedBox(height: 8),
          _line(isEn ? 'Total' : 'الإجمالي', total, strong: true),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEn ? 'Pay \$${total.toStringAsFixed(2)}' : 'دفع \$${total.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(isEn ? 'Cancel' : 'إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, double value, {bool strong = false}) {
    final style = strong
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('\$${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
