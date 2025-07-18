import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final String feeId;
  
  const PaymentPage({Key? key, required this.feeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Gateway',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Fee ID: $feeId'),
            const SizedBox(height: 16),
            const Text('Payment interface will be integrated here'),
          ],
        ),
      ),
    );
  }
}
