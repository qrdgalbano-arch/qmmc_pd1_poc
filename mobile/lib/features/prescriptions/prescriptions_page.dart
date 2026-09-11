import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exercise Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seated Knee Extension',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sit upright. Slowly straighten one knee, then lower it.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '10 repetitions · Up to 1 minute',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Schedule: Monday, Wednesday, Friday',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
