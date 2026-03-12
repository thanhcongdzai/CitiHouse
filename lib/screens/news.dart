import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  static const List<Map<String, String>> _mockNews = [
    {
      'title': 'Home Prices Rise 6% Year-Over-Year in Major Metro Areas',
      'description':
          'Real estate markets in cities like New York, Miami, and Los Angeles saw continued price growth in Q1 2025, driven by limited inventory and steady demand from first-time buyers.',
      'author': 'Redfin Research Team',
      'date': '10/03/2026',
      'image': 'https://images.unsplash.com/photo-1560520653-9e0e4c89eb11?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Mortgage Rates Drop Below 6.5% for the First Time Since 2022',
      'description':
          'A significant dip in the 30-year fixed mortgage rate is bringing buyers back to the market, with applications jumping 18% in the past two weeks alone.',
      'author': 'Housing Wire Editorial',
      'date': '08/03/2026',
      'image': 'https://images.unsplash.com/photo-1554469384-e58fac16e23a?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Luxury Condos Surge in Sunbelt Cities',
      'description':
          'Austin, Nashville, and Phoenix are seeing record-breaking luxury condo developments as remote work continues to attract high-income earners from coastal markets.',
      'author': 'Fortune Real Estate',
      'date': '07/03/2026',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'First-Time Buyers Face Tough Competition Despite More Listings',
      'description':
          'Even as new listings hit a three-year high, entry-level homes continue to sell above asking price due to fierce competition. Experts recommend getting pre-approved early.',
      'author': 'Zillow Market Insights',
      'date': '05/03/2026',
      'image': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Green Buildings Attract Premium Prices in 2026',
      'description':
          'Energy-efficient, eco-certified properties are commanding a 10–15% premium over standard homes, as buyers prioritize sustainability and lower utility costs.',
      'author': 'Green Building Journal',
      'date': '03/03/2026',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&auto=format&fit=crop&q=60',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _mockNews.length,
      itemBuilder: (context, index) {
        final item = _mockNews[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Image.network(
                item['image']!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.7),
                        colorScheme.secondary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.article, size: 48, color: Colors.white70),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Real Estate News',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      item['title']!,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      item['description']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Footer: author + date
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['author']!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: colorScheme.outline),
                          ),
                        ),
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          item['date']!,
                          style: TextStyle(
                              fontSize: 12, color: colorScheme.outline),
                        ),
                      ],
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
