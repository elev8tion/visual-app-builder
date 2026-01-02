import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/editor/editor_bloc.dart';
import '../../../core/templates/project_templates.dart';
import '../../../core/services/project_manager_service.dart';

/// Dialog for creating a new Flutter project
class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController(text: 'com.example');

  ProjectTemplate _selectedTemplate = ProjectTemplate.blank;
  StateManagement _selectedStateManagement = StateManagement.provider;
  String? _outputPath;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final path = await ProjectManagerService.instance.getDefaultProjectDirectory();
    setState(() => _outputPath = path);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.create_new_folder, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('New Project', style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Project name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'my_app',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a project name';
                    }
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
                      return 'Use lowercase letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Organization
                TextFormField(
                  controller: _orgController,
                  decoration: const InputDecoration(
                    labelText: 'Organization',
                    hintText: 'com.example',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Output path
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _outputPath ?? 'Select location...',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _pickLocation,
                      child: const Text('Browse'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Template selection
                Text('Template', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: ProjectTemplate.values.length,
                    itemBuilder: (context, index) {
                      final template = ProjectTemplate.values[index];
                      final config = ProjectTemplates.getTemplate(template);
                      final isSelected = template == _selectedTemplate;

                      return InkWell(
                        onTap: () => setState(() => _selectedTemplate = template),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surface,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                config?.icon ?? '📄',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                config?.name ?? template.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // State management
                Row(
                  children: [
                    Text('State Management:', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 16),
                    DropdownButton<StateManagement>(
                      value: _selectedStateManagement,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStateManagement = value);
                        }
                      },
                      items: StateManagement.values.map((sm) {
                        return DropdownMenuItem(
                          value: sm,
                          child: Text(sm.name.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isCreating ? null : _createProject,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? 'Creating...' : 'Create Project'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final path = await ProjectManagerService.instance.pickProjectLocation();
    if (path != null) {
      setState(() => _outputPath = path);
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate() || _outputPath == null) {
      return;
    }

    setState(() => _isCreating = true);

    context.read<EditorBloc>().add(CreateNewProject(
      name: _nameController.text,
      outputPath: _outputPath!,
      template: _selectedTemplate,
      stateManagement: _selectedStateManagement,
      organization: _orgController.text,
    ));

    Navigator.of(context).pop();
  }
}
