import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/editor/editor_bloc.dart';
import '../../../core/templates/project_templates.dart';
import '../../../core/services/service_locator.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final path = await ServiceLocator.instance.projectManager.getDefaultProjectDirectory();
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

    return BlocListener<EditorBloc, EditorState>(
      listener: (context, state) {
        // Auto-close dialog when project creation completes successfully
        if (state is EditorLoaded &&
            !state.isCreatingProject &&
            state.project != null &&
            state.generationProgress >= 1.0) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
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
                  const SizedBox(height: 16),

                  // Progress indicator (shown during creation)
                  BlocBuilder<EditorBloc, EditorState>(
                    builder: (context, state) {
                      if (state is EditorLoaded && state.isCreatingProject) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: state.generationProgress),
                            const SizedBox(height: 8),
                            Text(
                              state.generationStatus ?? 'Creating project...',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            // Show last few log messages
                            if (state.generationLog.isNotEmpty)
                              Container(
                                height: 60,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListView.builder(
                                  itemCount: state.generationLog.length > 3
                                      ? 3
                                      : state.generationLog.length,
                                  itemBuilder: (context, index) {
                                    final logIndex = state.generationLog.length > 3
                                        ? state.generationLog.length - 3 + index
                                        : index;
                                    return Text(
                                      state.generationLog[logIndex],
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      BlocBuilder<EditorBloc, EditorState>(
                        builder: (context, state) {
                          final isCreating = state is EditorLoaded && state.isCreatingProject;
                          return FilledButton.icon(
                            onPressed: isCreating ? null : _createProject,
                            icon: isCreating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add),
                            label: Text(isCreating ? 'Creating...' : 'Create Project'),
                          );
                        },
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
  }

  Future<void> _pickLocation() async {
    // On web, show a dialog to enter the path manually
    // The path should be a valid directory on the backend server's filesystem
    final controller = TextEditingController(text: _outputPath);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Project Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Path',
            hintText: '/Users/username/Documents/FlutterProjects',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _outputPath = result);
    }
  }

  Future<void> _createProject() async {
    debugPrint('=== _createProject called ===');
    debugPrint('Project name: ${_nameController.text}');
    debugPrint('Output path: $_outputPath');
    debugPrint('Form valid: ${_formKey.currentState?.validate()}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    if (_outputPath == null) {
      debugPrint('Output path is null');
      return;
    }

    debugPrint('Dispatching CreateNewProject event...');

    context.read<EditorBloc>().add(CreateNewProject(
      name: _nameController.text,
      outputPath: _outputPath!,
      template: _selectedTemplate,
      stateManagement: _selectedStateManagement,
      organization: _orgController.text,
    ));

    // Dialog stays open - BlocListener will close it when creation completes
  }
}
