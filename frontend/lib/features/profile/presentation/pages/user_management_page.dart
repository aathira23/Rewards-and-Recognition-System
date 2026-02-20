import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.users);
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'User Management',
              subtitle: 'Manage system users, roles, and departments',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add User'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              )),
            if (_error != null)
              EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load users',
                message: _error,
                onRetry: _loadUsers,
              ),
            if (!_isLoading && _users.isEmpty && _error == null)
              const EmptyStateView(
                icon: Icons.people_outline_rounded,
                title: 'No users found',
                message: 'Add your first user to get started.',
              ),
            if (!_isLoading && _users.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DataTable(
                    headingRowColor:
                        WidgetStatePropertyAll(Colors.grey.shade50),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(user['email'] ?? '',
                              style: AppTextStyles.body(
                                  color: Colors.grey.shade600))),
                          DataCell(_buildRoleBadge(user['role'] ?? '')),
                          DataCell(Text(
                              user['department']?['name'] ?? 'Unassigned',
                              style: AppTextStyles.body(
                                  color: Colors.grey.shade600))),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.edit,
                                  size: 18, color: theme.colorScheme.primary),
                              onPressed: () =>
                                  _showEditUserDialog(context, user),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        color = Colors.purple;
        break;
      case 'HR':
        color = Colors.purple;
        break;
      case 'DEPT_HEAD':
        color = Colors.blue;
        break;
      case 'MANAGER':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(role, style: AppTextStyles.captionBold(color: color)),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '', email = '', password = '', role = 'EMPLOYEE';

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Create New User',
        maxWidth: 500,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (v) => email = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (v) => password = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Role'),
                initialValue: role,
                items: ['EMPLOYEE', 'MANAGER', 'DEPT_HEAD', 'HR', 'ADMIN']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => role = v ?? 'EMPLOYEE',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                try {
                  final client = sl<ApiClient>();
                  await client.post(ApiConstants.users, data: {
                    'name': name,
                    'email': email,
                    'password': password,
                    'role': role,
                  });
                  _loadUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('User created successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    String name = user['name'] ?? '';
    String role = user['role'] ?? 'EMPLOYEE';
    final int userId = user['id'];

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Edit ${user['name']}',
        maxWidth: 500,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                initialValue: name,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Role'),
                initialValue: role,
                items: ['EMPLOYEE', 'MANAGER', 'DEPT_HEAD', 'HR', 'ADMIN']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => role = v ?? role,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final client = sl<ApiClient>();
                await client.patch('${ApiConstants.userUpdate}$userId',
                    data: {'name': name, 'role': role});
                _loadUsers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
