import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/department_entity.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/department_bloc.dart';
import '../bloc/department_event.dart';
import '../bloc/department_state.dart';

class DepartmentManagementPage extends StatelessWidget {
  const DepartmentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DepartmentBloc>()..add(LoadDepartments()),
      child: const _DepartmentManagementView(),
    );
  }
}

class _DepartmentManagementView extends StatelessWidget {
  const _DepartmentManagementView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DepartmentBloc, DepartmentState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          AppSnackbar.success(context, state.successMessage!);
        }
        if (state.error != null) {
          AppSnackbar.error(context, state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: 'Department Management',
                  subtitle: 'Create and manage organizational departments',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => context
                            .read<DepartmentBloc>()
                            .add(LoadDepartments()),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add_business, size: 18),
                        label: const Text('Add Department'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!state.isLoading && state.departments.isEmpty)
                  const EmptyStateView(
                    icon: Icons.business_outlined,
                    title: 'No departments found',
                    message: 'Click "Add Department" to create your first one.',
                  ),
                if (!state.isLoading && state.departments.isNotEmpty)
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: state.departments.map((dept) {
                      return Container(
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.business_rounded,
                                  color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dept.name,
                                      style: AppTextStyles.cardTitle()),
                                  Text('ID: ${dept.id}',
                                      style: AppTextStyles.caption(
                                          color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showEditDialog(context, dept);
                                } else if (action == 'delete') {
                                  context
                                      .read<DepartmentBloc>()
                                      .add(DeleteDepartment(id: dept.id));
                                }
                              },
                              icon: const Icon(Icons.more_vert, size: 18),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final bloc = context.read<DepartmentBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Create Department',
        maxWidth: 400,
        showCloseButton: false,
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(CreateDepartment(name: controller.text));
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DepartmentEntity dept) {
    final controller = TextEditingController(text: dept.name);
    final bloc = context.read<DepartmentBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Edit Department',
        maxWidth: 400,
        showCloseButton: false,
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(UpdateDepartment(id: dept.id, name: controller.text));
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
