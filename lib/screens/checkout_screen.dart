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
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await context.read<AppState>().purchaseCourse(widget.courseId);
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase confirmed')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final course = app.courseById(widget.courseId);
    final theme = Theme.of(context);

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ),
      );
    }

    final tax = course.price * 0.07;
    final total = course.price + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Order summary', style: theme.textTheme.titleLarge),
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
          Text('Payment method', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'card',
            groupValue: _method,
            onChanged: _busy ? null : (v) => setState(() => _method = v!),
            title: const Text('Card ending •••• 4242'),
            subtitle: const Text('Secured processing'),
          ),
          RadioListTile<String>(
            value: 'wallet',
            groupValue: _method,
            onChanged: _busy ? null : (v) => setState(() => _method = v!),
            title: const Text('CourseLab Wallet'),
            subtitle: const Text('Available balance'),
          ),
          const Divider(height: 32),
          _line('Subtotal', course.price),
          _line('Estimated tax', tax),
          const SizedBox(height: 8),
          _line('Total', total, strong: true),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Pay \$${total.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
