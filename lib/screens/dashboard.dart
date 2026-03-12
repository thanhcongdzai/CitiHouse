import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final List<Map<String, String>> mockData = [
    {
      'title': 'Luxury Villa in Beverly Hills',
      'intro': 'Experience the ultimate luxury lifestyle with this stunning 5-bedroom villa featuring panoramic city views.',
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Modern Apartment in Downtown',
      'intro': 'Sleek and contemporary 2-bedroom apartment located in the heart of the bustling financial district.',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=500&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Cozy Suburban Family Home',
      'intro': 'Perfect home for a growing family, featuring a spacious backyard, modern kitchen, and quiet neighborhood.',
      'image': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=500&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Beachfront Condo',
      'intro': 'Wake up to the sound of waves in this beautiful beachfront condo. recently renovated with premium finishing.',
      'image': 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Rustic Mountain Cabin',
      'intro': 'Escape the city to this charming rustic cabin nestled in the mountains. Perfect for weekend getaways.',
      'image': 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=500&auto=format&fit=crop&q=60'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mockData.length,
      itemBuilder: (context, index) {
        final item = mockData[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                item['image']!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.error, size: 50, color: Colors.grey,)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['intro']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
