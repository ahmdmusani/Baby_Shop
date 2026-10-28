import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/faq_model.dart';
import '../widgets/faq_accordion.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'FAQs'),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firebaseService.getCollectionStream('faqs'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading FAQs: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No FAQs available.', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
            }

            // Convert to model and sort by order
            List<FaqItemModel> faqs = docs.map((doc) => FaqItemModel.fromMap(doc.data(), doc.id)).toList();
            faqs.sort((a, b) => a.order.compareTo(b.order));

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return FaqAccordion(
                  question: faq.question,
                  answer: faq.answer,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
