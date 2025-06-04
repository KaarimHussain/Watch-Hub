import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> faqItems = [
    FAQItem(
      question: "How do I track my watch order?",
      answer:
          "You can track your order by going to 'My Orders' in your profile section. Each order has a tracking number that provides real-time updates on your watch's delivery status.",
    ),
    FAQItem(
      question: "What is your return policy for watches?",
      answer:
          "We offer a 30-day return policy for all watches. The watch must be in original condition with all packaging, certificates, and accessories. Custom or engraved watches cannot be returned.",
    ),
    FAQItem(
      question: "Are the watches authentic?",
      answer:
          "Yes, all watches sold on WatchHub are 100% authentic. We source directly from authorized dealers and provide certificates of authenticity with every purchase.",
    ),
    FAQItem(
      question: "Do you offer warranty on watches?",
      answer:
          "All watches come with manufacturer warranty. Luxury watches typically have 2-3 years warranty, while premium brands may offer extended warranty periods. Check individual product pages for specific warranty details.",
    ),
    FAQItem(
      question: "What payment methods do you accept?",
      answer:
          "We accept all major credit cards (Visa, MasterCard, American Express), PayPal, Apple Pay, Google Pay, and bank transfers for high-value purchases.",
    ),
    FAQItem(
      question: "How long does shipping take?",
      answer:
          "Standard shipping takes 3-5 business days. Express shipping (1-2 days) is available for an additional fee. International shipping may take 7-14 business days depending on location.",
    ),
    FAQItem(
      question: "Can I get my watch serviced through WatchHub?",
      answer:
          "Yes, we partner with authorized service centers for watch maintenance and repairs. Contact our customer support for service scheduling and pricing information.",
    ),
    FAQItem(
      question: "Do you offer watch insurance?",
      answer:
          "We partner with leading insurance providers to offer comprehensive watch insurance. Coverage includes theft, damage, and loss. Insurance options are available during checkout.",
    ),
    FAQItem(
      question: "How do I know if a watch will fit my wrist?",
      answer:
          "Each product page includes detailed sizing information. We also offer a virtual try-on feature and size guides. If the fit isn't perfect, our exchange policy allows for size adjustments.",
    ),
    FAQItem(
      question: "Can I reserve a watch before purchasing?",
      answer:
          "Yes, you can reserve watches for up to 48 hours by adding them to your wishlist or using our 'Hold for Me' feature. This is especially useful for limited edition pieces.",
    ),
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFAQs =
        faqItems
            .where(
              (faq) =>
                  faq.question.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  faq.answer.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ'), centerTitle: true),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredFAQs.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    title: Text(
                      filteredFAQs[index].question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconColor: theme.colorScheme.primary,
                    collapsedIconColor: theme.colorScheme.secondary,
                    children: [
                      Text(
                        filteredFAQs[index].answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Contact Support Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to contact support
                },
                icon: const Icon(Icons.support_agent, size: 24),
                label: const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
