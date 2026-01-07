import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String _selectedRole = 'All';
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _selectAll = false;
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<String> _selectedUsers = {};
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data()))
          .where((user) => user.role.toLowerCase() != 'admin')
          .toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading users: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchesRole = _selectedRole == 'All' ||
          (user.role.toLowerCase() == _selectedRole.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'All' || _getUserStatus(user) == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          user.displayName
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesStatus && matchesSearch;
    }).toList();
  }

  String _getUserStatus(UserModel user) {
    // Map UserStatus enum to display status
    if (user.status == UserStatus.approved) {
      return 'Active';
    } else if (user.status == UserStatus.suspended) {
      return 'Suspended';
    } else {
      return 'Unknown';
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final newStatus =
          status == 'Active' ? UserStatus.approved : UserStatus.suspended;
      final newIsActive = status == 'Active';

      // Update both status and isActive fields
      await _databaseService.updateUserField(userId, 'status', newStatus.index);
      await _databaseService.updateUserField(userId, 'isActive', newIsActive);

      // Find the user object
      final userIndex = _users.indexWhere((user) => user.uid == userId);
      final user = userIndex != -1 ? _users[userIndex] : null;

      // Update local state
      setState(() {
        if (userIndex != -1) {
          final updatedUser = UserModel(
            uid: _users[userIndex].uid,
            email: _users[userIndex].email,
            role: _users[userIndex].role,
            displayName: _users[userIndex].displayName,
            phoneNumber: _users[userIndex].phoneNumber,
            languages: _users[userIndex].languages,
            toursCompleted: _users[userIndex].toursCompleted,
            averageRating: _users[userIndex].averageRating,
            photoURL: _users[userIndex].photoURL,
            createdAt: _users[userIndex].createdAt,
            activeStatus: null, // Not using activeStatus anymore
            favoriteDestination: _users[userIndex].favoriteDestination,
            specializations: _users[userIndex].specializations,
            status: newStatus,
            isActive: newIsActive,
          );
          _users[userIndex] = updatedUser;
          _applyFilters();
        }
      });

      // Create notifications for both admin and affected user if user was found
      if (user != null) {
        final currentAdmin = FirebaseAuth.instance.currentUser;
        if (currentAdmin != null) {
          // Create notification for admin
          final adminNotification = newStatus == UserStatus.approved
              ? _notificationService.createUserReactivatedNotification(
                  userId: currentAdmin.uid,
                  userName: user.displayName ?? user.email,
                )
              : _notificationService.createUserSuspendedNotification(
                  userId: currentAdmin.uid,
                  userName: user.displayName ?? user.email,
                  reason: 'Administrative action',
                );

          await _notificationService.createNotification(adminNotification);

          // Create notification for the affected user
          final userNotification = newStatus == UserStatus.approved
              ? _notificationService.createUserReactivatedNotification(
                  userId: user.uid,
                  userName: user.displayName ?? user.email,
                )
              : _notificationService.createUserSuspendedNotification(
                  userId: user.uid,
                  userName: user.displayName ?? user.email,
                  reason: 'Administrative action',
                );

          await _notificationService.createNotification(userNotification);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'User Management',
                style: AppTheme.headlineLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Users',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage users, roles, and account status',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Loading/Error States
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_errorMessage.isNotEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(_errorMessage, style: AppTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Filters and Search
            Column(
              children: [
                Row(
                  children: [
                    // Role Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        underline: Container(),
                        items: ['All', 'Tourist', 'Tour Guide', 'Admin']
                            .map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        underline: Container(),
                        items: ['All', 'Active', 'Suspended'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Search
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Bulk Actions (only show when users are selected)
                if (_selectedUsers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedUsers.length} user(s) selected',
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _bulkDeactivateUsers,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Deactivate'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _bulkActivateUsers,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.successColor,
                          ),
                          child: const Text('Activate'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearSelection,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Users Table
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 800),
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Row(
                            children: [
                              Checkbox(
                                value: _selectAll,
                                onChanged: (_) => _toggleSelectAll(),
                              ),
                              const Text('User'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Role')),
                        const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('Join Date')),
                        const DataColumn(label: Text('Last Active')),
                        const DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredUsers.map((user) {
                        final userId = user.uid;
                        return DataRow(
                          selected: _selectedUsers.contains(userId),
                          onSelectChanged: (selected) {
                            if (selected != null) {
                              _toggleUserSelection(userId);
                            }
                          },
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Checkbox(
                                    value: _selectedUsers.contains(userId),
                                    onChanged: (selected) =>
                                        _toggleUserSelection(userId),
                                  ),
                                  CircleAvatar(
                                    backgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    child: Text(
                                        user.displayName?[0] ?? user.email[0]),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'No Name',
                                        style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        user.email,
                                        style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(_buildRoleChip(user.role)),
                            DataCell(_buildStatusChip(_getUserStatus(user))),
                            DataCell(Text(
                                user.createdAt?.toString().split(' ')[0] ??
                                    'N/A')),
                            DataCell(Text(
                                'Online')), // TODO: Implement last active tracking
                            DataCell(
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  _handleUserAction(user, action);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Text(_getUserStatus(user) == 'Active'
                                        ? 'Deactivate'
                                        : 'Activate'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete User'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Summary
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Text(
                    'Total Users: ${_filteredUsers.length}',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 32),
                  Text(
                    'Active: ${_filteredUsers.where((u) => _getUserStatus(u) == 'Active').length}',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(width: 32),
                  Text(
                    'Suspended: ${_filteredUsers.where((u) => _getUserStatus(u) == 'Suspended').length}',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = AppTheme.primaryColor;
        break;
      case 'guide':
        color = AppTheme.accentColor;
        break;
      default:
        color = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color =
        status == 'Active' ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleUserAction(UserModel user, String action) {
    switch (action) {
      case 'view':
        _showUserDetailsDialog(user);
        break;
      case 'status':
        final currentStatus = _getUserStatus(user);
        final newStatus = currentStatus == 'Active' ? 'Suspended' : 'Active';
        _showStatusChangeDialog(user, newStatus);
        break;
      case 'delete':
        _showDeleteDialog(user);
        break;
    }
  }

  void _showUserDetailsDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user.displayName ?? 'User Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Role', user.role),
                _buildDetailRow('Status', _getUserStatus(user)),
                _buildDetailRow('Phone', user.phoneNumber ?? 'Not provided'),
                _buildDetailRow(
                    'Languages', user.languages?.join(', ') ?? 'Not specified'),
                _buildDetailRow(
                    'Tours Completed', user.toursCompleted?.toString() ?? '0'),
                _buildDetailRow(
                    'Average Rating', user.averageRating?.toString() ?? 'N/A'),
                _buildDetailRow('Joined', user.createdAt?.toString() ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showStatusChangeDialog(UserModel user, String newStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${newStatus} User'),
          content: Text(
              'Are you sure you want to ${newStatus.toLowerCase()} ${user.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserStatus(user.uid, newStatus);
              },
              style: TextButton.styleFrom(
                  foregroundColor: newStatus == 'Active'
                      ? AppTheme.successColor
                      : AppTheme.errorColor),
              child: Text(newStatus),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
              'Are you sure you want to permanently delete ${user.displayName}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement user deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${user.displayName} deletion - Coming Soon!')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedUsers.clear();
      } else {
        _selectedUsers.addAll(_filteredUsers.map((user) => user.uid));
      }
      _selectAll = !_selectAll;
    });
  }

  void _bulkActivateUsers() {
    for (final userId in _selectedUsers) {
      _updateUserStatus(userId, 'Active');
    }
    _clearSelection();
  }

  void _bulkDeactivateUsers() {
    for (final userId in _selectedUsers) {
      _updateUserStatus(userId, 'Suspended');
    }
    _clearSelection();
  }

  void _clearSelection() {
    setState(() {
      _selectedUsers.clear();
      _selectAll = false;
    });
  }
}
