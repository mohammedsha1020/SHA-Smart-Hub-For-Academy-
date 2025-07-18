import 'package:flutter/material.dart';

class FeeDetailsPage extends StatelessWidget {
  final String feeId;
  
  const FeeDetailsPage({Key? key, required this.feeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Fee Details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Fee ID: $feeId'),
            const SizedBox(height: 16),
            const Text('Detailed fee information will be displayed here'),
          ],
        ),
      ),
    );
  }
}
