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
    final app = context.read<AppState>();
    final isEn = app.locale.languageCode == 'en';
    
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

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
            Text(isEn ? 'Add Payment Method' : 'إضافة وسيلة دفع',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isEn ? 'Card Holder Name' : 'اسم صاحب البطاقة',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: InputDecoration(
                labelText: isEn ? 'Card Number' : 'رقم البطاقة',
                hintText: 'XXXX XXXX XXXX XXXX',
                prefixIcon: const Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Expiry Date' : 'تاريخ الانتهاء',
                      hintText: 'MM/YY',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: 'XXX',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      numberController.text.length < 12 ||
                      expiryController.text.isEmpty ||
                      cvvController.text.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEn ? 'Please enter valid card details' : 'يرجى إدخال بيانات البطاقة بشكل صحيح')),
                    );
                    return;
                  }

                  final last4 = numberController.text
                      .substring(numberController.text.length - 4);
                  
                  setState(() => _isLoading = true);
                  Navigator.pop(ctx);
                  
                  await context.read<AppState>().addPaymentMethod(
                        cardHolderName: nameController.text,
                        cardNumber: numberController.text,
                        last4Digits: last4,
                        expiryDate: expiryController.text,
                        cvv: cvvController.text,
                      );
                  
                  setState(() => _isLoading = false);
                },
                child: Text(isEn ? 'Save Card' : 'حفظ البطاقة'),
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
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final methods = app.paymentMethods;

    return Scaffold(
      appBar: AppBar(title: Text(isEn ? 'Payment Methods' : 'وسائل الدفع')),
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
                      Text(isEn ? 'No payment methods saved' : 'لا توجد وسائل دفع محفوظة'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showAddPaymentSheet,
                        icon: const Icon(Icons.add),
                        label: Text(isEn ? 'Add Method' : 'إضافة وسيلة'),
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
                            '${card.cardHolderName} • ${isEn ? 'Exp' : 'تنتهي'}: ${card.expiryDate}'),
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
