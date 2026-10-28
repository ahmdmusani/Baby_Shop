import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({Key? key}) : super(key: key);

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _pink = AppTheme.primaryColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text(
          'Customer Support Complaints',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _pink,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: _pink,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'OPEN'),
            Tab(text: 'IN PROGRESS'),
            Tab(text: 'RESOLVED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketsList(null),
          _buildTicketsList('open'),
          _buildTicketsList('in_progress'),
          _buildTicketsList('resolved'),
        ],
      ),
    );
  }

  Widget _buildTicketsList(String? statusFilter) {
    Query query = FirebaseFirestore.instance.collection('support_tickets');
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    // Sort by createdAt
    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        if (snap.hasError) {
          // In case the collection index is still building, try fallback without order
          return StreamBuilder<QuerySnapshot>(
            stream: (statusFilter != null 
                ? FirebaseFirestore.instance.collection('support_tickets').where('status', isEqualTo: statusFilter)
                : FirebaseFirestore.instance.collection('support_tickets')).snapshots(),
            builder: (context2, snap2) {
              if (snap2.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _pink));
              }
              final docs = snap2.data?.docs ?? [];
              if (docs.isEmpty) return _emptyState();
              return _buildListLayout(docs);
            },
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState();
        }

        return _buildListLayout(docs);
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_chat_read_outlined, size: 60, color: Colors.black12),
          const SizedBox(height: 12),
          Text(
            'No support tickets found.',
            style: GoogleFonts.poppins(color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(List<DocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final String id = data['id'] ?? '';
        final String title = data['title'] ?? 'Ticket';
        final String userName = data['userName'] ?? 'Customer';
        final String userEmail = data['userEmail'] ?? '';
        final String cat = data['category'] ?? 'Other';
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
            border: Border.all(color: Colors.black.withOpacity(0.02)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3142)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'User: $userName ($userEmail)',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _pink),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category: ${cat.toUpperCase()}  |  ${dt.day}/${dt.month}/${dt.year}',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Reply →',
                      style: GoogleFonts.poppins(fontSize: 11, color: _pink, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminTicketChatScreen(ticketId: id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AdminTicketChatScreen extends StatefulWidget {
  final String ticketId;
  const AdminTicketChatScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<AdminTicketChatScreen> createState() => _AdminTicketChatScreenState();
}

class _AdminTicketChatScreenState extends State<AdminTicketChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  static const _pink = AppTheme.primaryColor;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
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
            'senderName': 'Support Admin',
            'message': text,
            'timestamp': Timestamp.now(),
          }
        ])
      });
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

  Future<void> _updateStatus(String status) async {
    try {
      await FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).update({
        'status': status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _pink)),
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
        final String clientName = data['userName'] ?? 'Client';
        final String clientEmail = data['userEmail'] ?? '';
        final List repliesList = data['replies'] ?? [];

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            shape: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.04),
                width: 1,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'User: $clientName ($clientEmail)',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Ticket details top card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Issue:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2D3142), height: 1.4),
                    ),
                    const Divider(height: 24),
                    // Action controls for status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Status: ${status.replaceAll('_', ' ').toUpperCase()}',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'resolved' ? Colors.green : Colors.orange),
                        ),
                        Row(
                          children: [
                            if (status == 'open')
                              ElevatedButton(
                                onPressed: () => _updateStatus('in_progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  elevation: 0,
                                ),
                                child: Text('Process', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
                              ),
                            if (status == 'in_progress' || status == 'open') ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateStatus('resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  elevation: 0,
                                ),
                                child: Text('Resolve', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
                              ),
                            ],
                            if (status == 'resolved')
                              ElevatedButton(
                                onPressed: () => _updateStatus('open'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  elevation: 0,
                                ),
                                child: Text('Reopen', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
                              ),
                          ],
                        )
                      ],
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
                    final bool isAdmin = senderId == adminUser?.uid || senderName == 'Support Admin';

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAdmin ? _pink : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isAdmin)
                              Text(
                                senderName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _pink,
                                ),
                              ),
                            if (!isAdmin) const SizedBox(height: 4),
                            Text(
                              msg,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isAdmin ? Colors.white : const Color(0xFF2D3142),
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
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    ],
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
