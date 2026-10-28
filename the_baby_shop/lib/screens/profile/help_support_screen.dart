import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Order';
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I track my order?',
      'answer': 'You can track your order directly from the "My Orders" screen in your profile. Once your order status changes to Shipped, a tracking timeline will display step-by-step progress.'
    },
    {
      'question': 'What is your return policy?',
      'answer': 'We accept returns within 14 days of delivery for unused, unopened products in original packaging. Please submit a complaint ticket under the "Product" category to initiate a return request.'
    },
    {
      'question': 'What payment methods do you accept?',
      'answer': 'We accept Cash on Delivery (COD) as well as credit/debit card payments. Rest assured that online card payments are fully secured.'
    },
    {
      'question': 'How long does delivery take?',
      'answer': 'Orders within major cities (like Karachi, Lahore, Islamabad) are delivered within 2-3 business days. Deliveries to other regions across Pakistan take 3-5 business days.'
    },
    {
      'question': 'Can I cancel my order after placing it?',
      'answer': 'You can cancel your order from the order detail page as long as the status is "Pending". Once the status is updated to "Packed" or "Shipped", the order cannot be cancelled.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('support_tickets').doc();
      
      // Fetch user profile info
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String userName = userDoc.exists ? (userDoc.data()?['fullName'] ?? 'Anonymous') : (user.displayName ?? 'Anonymous');
      final String userEmail = user.email ?? '';

      await docRef.set({
        'id': docRef.id,
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'status': 'open',
        'createdAt': Timestamp.now(),
        'replies': [],
      });

      _titleController.clear();
      _descController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created successfully!'), backgroundColor: Colors.green),
        );
        _tabController.animateTo(2); // Switch to "My Tickets" tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'FAQs', icon: Icon(Icons.help_outline_rounded, size: 20)),
            Tab(text: 'Submit Ticket', icon: Icon(Icons.rate_review_outlined, size: 20)),
            Tab(text: 'My Tickets', icon: Icon(Icons.receipt_long_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqsTab(),
          _buildSubmitTicketTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildFaqsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          child: ExpansionTile(
            title: Text(
              faq['question']!,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
            ),
            iconColor: AppTheme.primaryColor,
            collapsedIconColor: AppTheme.textSecondary,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  faq['answer']!,
                  style: GoogleFonts.poppins(height: 1.5, fontSize: 13, color: AppTheme.textSecondary),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitTicketTab() {
    final categories = ['Order', 'Payment', 'Product', 'Other'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit a Complaint / Request',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'We will get back to you as soon as possible.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Category Dropdown
            Text(
              'Category',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
              ),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Subject / Title',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Broken item received',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a subject' : null,
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'Detailed Description',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your issue in detail...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Submit Ticket',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view your support tickets.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_chat_read_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No support tickets raised yet.',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String id = data['id'] ?? '';
            final String title = data['title'] ?? 'Support Ticket';
            final String cat = data['category'] ?? 'General';
            final String desc = data['description'] ?? '';
            final String status = data['status'] ?? 'open';
            final Timestamp? created = data['createdAt'] as Timestamp?;
            final DateTime dt = created?.toDate() ?? DateTime.now();

            Color statusColor;
            switch (status) {
              case 'in_progress':
                statusColor = Colors.orange;
                break;
              case 'resolved':
                statusColor = Colors.green;
                break;
              default:
                statusColor = Colors.blue;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketChatScreen(ticketId: id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cat.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${dt.day}/${dt.month}/${dt.year}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Open Chat',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryColor),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TicketChatScreen extends StatefulWidget {
  final String ticketId;
  const TicketChatScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String userName) async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).update({
        'replies': FieldValue.arrayUnion([
          {
            'senderId': user.uid,
            'senderName': userName,
            'message': text,
            'timestamp': Timestamp.now(),
          }
        ])
      });
      // Scroll to bottom after message sent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Ticket not found.')),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'Ticket Chat';
        final String desc = data['description'] ?? '';
        final String status = data['status'] ?? 'open';
        final String userName = data['userName'] ?? 'User';
        final List repliesList = data['replies'] ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Status: ${status.replaceAll('_', ' ').toUpperCase()}',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'resolved' ? Colors.green : Colors.orange),
                ),
              ],
            ),
            centerTitle: false,
          ),
          body: Column(
            children: [
              // Ticket details top card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Description:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),

              // Chat replies list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: repliesList.length,
                  itemBuilder: (context, idx) {
                    final reply = repliesList[idx] as Map<String, dynamic>;
                    final String msg = reply['message'] ?? '';
                    final String senderId = reply['senderId'] ?? '';
                    final String senderName = reply['senderName'] ?? 'Support';
                    final bool isMe = senderId == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                senderName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              msg,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isMe ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Message Input Bar
              if (status != 'resolved')
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type your reply here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(userName),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : () => _sendMessage(userName),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              else
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Text(
                        'This ticket is marked as resolved.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
