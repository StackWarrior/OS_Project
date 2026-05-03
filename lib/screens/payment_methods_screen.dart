import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method.dart';
import '../state/app_state.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = false;

  void _showAddPaymentSheet() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Payment Method',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Card Holder Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: 'XXXX XXXX XXXX 1234',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                hintText: 'MM/YY',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      numberController.text.length < 4 ||
                      expiryController.text.isEmpty) return;

                  final last4 = numberController.text
                      .substring(numberController.text.length - 4);
                  
                  setState(() => _isLoading = true);
                  Navigator.pop(ctx);
                  
                  await context.read<AppState>().addPaymentMethod(
                        cardHolderName: nameController.text,
                        last4Digits: last4,
                        expiryDate: expiryController.text,
                      );
                  
                  setState(() => _isLoading = false);
                },
                child: const Text('Save Card'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = context.watch<AppState>().paymentMethods;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : methods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No payment methods saved'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showAddPaymentSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Method'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final card = methods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: Text('**** **** **** ${card.last4Digits}'),
                        subtitle: Text(
                            '${card.cardHolderName} • Exp: ${card.expiryDate}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => context
                              .read<AppState>()
                              .deletePaymentMethod(card.id),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: methods.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddPaymentSheet,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
