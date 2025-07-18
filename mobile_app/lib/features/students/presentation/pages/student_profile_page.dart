import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final String studentId;
  
  const StudentProfilePage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              'Student Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Student ID: $studentId'),
            const SizedBox(height: 16),
            const Text('Student details will be displayed here'),
          ],
        ),
      ),
    );
  }
}
