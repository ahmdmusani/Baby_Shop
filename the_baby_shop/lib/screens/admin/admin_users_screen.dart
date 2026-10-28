import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/admin_user_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_search_bar.dart';
import '../../widgets/admin/confirm_dialog.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text('Manage Users',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AdminSearchBar(
              hintText: 'Search users...',
              onChanged: provider.setSearchQuery,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdminUserModel>>(
              stream: provider.usersStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _pink));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final users = snap.data ?? [];
                provider.updateUserList(users);
                final filtered = provider.users;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.black12),
                        const SizedBox(height: 12),
                        Text('No users found.',
                            style: GoogleFonts.poppins(
                                color: Colors.black38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _UserTile(user: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    final dateStr = user.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
        : 'Unknown';

    return AnimatedOpacity(
      opacity: user.isDisabled ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: user.profileImage != null &&
                          user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null || user.profileImage!.isEmpty
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.fullName,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: const Color(0xFF2D3142)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        _RoleBadge(role: user.role),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: GoogleFonts.poppins(
                            color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        if (user.isDisabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
                            ),
                            child: Text('Disabled',
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.black38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (value) async {
                  if (value == 'toggle') {
                    await provider.updateUserStatus(
                        user.uid, !user.isDisabled);
                  } else if (value == 'delete') {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete User',
                      message:
                          'Are you sure you want to delete "${user.fullName}"?',
                    );
                    if (confirmed == true && context.mounted) {
                      await provider.deleteUser(user.uid);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.isDisabled
                              ? Icons.check_circle_outline_rounded
                              : Icons.block_rounded,
                          size: 18,
                          color: user.isDisabled
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          user.isDisabled ? 'Enable User' : 'Disable User',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 10),
                        Text('Delete User',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppTheme.primaryColor.withOpacity(0.08)
            : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdmin
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color:
              isAdmin ? AppTheme.primaryColor : Colors.blue,
        ),
      ),
    );
  }
}
