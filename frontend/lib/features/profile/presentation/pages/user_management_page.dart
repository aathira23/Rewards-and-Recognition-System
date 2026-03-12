import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/user_mgmt_bloc.dart';
import '../bloc/user_mgmt_event.dart';
import '../bloc/user_mgmt_state.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserMgmtBloc>()..add(LoadUsers()),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<UserMgmtBloc, UserMgmtState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            AppSnackbar.success(context, state.successMessage!);
          }
          if (state.error != null) {
            AppSnackbar.error(context, state.error!);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
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
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () =>
                            context.read<UserMgmtBloc>().add(LoadUsers()),
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
                if (state.isLoading && state.users.isEmpty)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  )),
                if (!state.isLoading &&
                    state.users.isEmpty &&
                    state.error == null)
                  const EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: 'No users found',
                    message: 'Add your first user to get started.',
                  ),
                if (state.users.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width -
                                (Responsive.showSidebar(context) ? 260 : 0) -
                                Responsive.pagePadding(context) * 2,
                          ),
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
                            rows: state.users.map((user) {
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
                                      user['department']?['name'] ??
                                          'Unassigned',
                                      style: AppTextStyles.body(
                                          color: Colors.grey.shade600))),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          size: 18,
                                          color: theme.colorScheme.primary),
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
                    ),
                  ),
              ],
            ),
          );
        },
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
        showCloseButton: false,
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
              DropdownMenu<String>(
                label: const Text('Role'),
                initialSelection: role,
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: InputDecorationTheme(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'EMPLOYEE', label: 'EMPLOYEE'),
                  DropdownMenuEntry(value: 'MANAGER', label: 'MANAGER'),
                  DropdownMenuEntry(value: 'DEPT_HEAD', label: 'DEPT_HEAD'),
                  DropdownMenuEntry(value: 'HR', label: 'HR'),
                  DropdownMenuEntry(value: 'ADMIN', label: 'ADMIN'),
                ],
                onSelected: (v) => role = v ?? 'EMPLOYEE',
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                context.read<UserMgmtBloc>().add(CreateUserRequested(
                      data: {
                        'name': name,
                        'email': email,
                        'password': password,
                        'role': role,
                      },
                    ));
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
        showCloseButton: false,
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
              DropdownMenu<String>(
                label: const Text('Role'),
                initialSelection: role,
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: InputDecorationTheme(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'EMPLOYEE', label: 'EMPLOYEE'),
                  DropdownMenuEntry(value: 'MANAGER', label: 'MANAGER'),
                  DropdownMenuEntry(value: 'DEPT_HEAD', label: 'DEPT_HEAD'),
                  DropdownMenuEntry(value: 'HR', label: 'HR'),
                  DropdownMenuEntry(value: 'ADMIN', label: 'ADMIN'),
                ],
                onSelected: (v) => role = v ?? role,
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
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UserMgmtBloc>().add(UpdateUserRequested(
                    id: userId,
                    data: {'name': name, 'role': role},
                  ));
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
