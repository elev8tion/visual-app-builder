import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/editor/editor_bloc.dart';
import '../../../core/services/project_manager_service.dart';

/// Dialog for AI-powered app generation from natural language prompts
class AIAppGeneratorDialog extends StatefulWidget {
  const AIAppGeneratorDialog({super.key});

  @override
  State<AIAppGeneratorDialog> createState() => _AIAppGeneratorDialogState();
}

class _AIAppGeneratorDialogState extends State<AIAppGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController(text: 'com.example');

  String? _outputPath;
  bool _isGenerating = false;

  static const _examplePrompts = [
    'A todo list app with categories and due dates',
    'A weather app showing 5-day forecast with location search',
    'An e-commerce app with product catalog and shopping cart',
    'A note-taking app with markdown support and tags',
    'A fitness tracker with workout logging and progress charts',
    'A recipe app with search, favorites, and shopping list',
  ];

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
    _promptController.dispose();
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
        if (state is EditorLoaded) {
          setState(() => _isGenerating = state.isGeneratingApp);
        }
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI App Generator', style: theme.textTheme.headlineSmall),
                          Text(
                            'Describe your app and AI will build it',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Project name and org
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Project Name',
                            hintText: 'my_ai_app',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
                              return 'Lowercase with underscores';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _orgController,
                          decoration: const InputDecoration(
                            labelText: 'Organization',
                            hintText: 'com.example',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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

                  // Prompt input
                  Text('Describe your app:', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _promptController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'I want to build a...\n\nDescribe the screens, features, and functionality you need.',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your app';
                        }
                        if (value.length < 20) {
                          return 'Please provide more detail';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Example prompts
                  Text('Try an example:', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _examplePrompts.map((prompt) {
                      return ActionChip(
                        label: Text(
                          prompt.length > 35 ? '${prompt.substring(0, 35)}...' : prompt,
                          style: theme.textTheme.bodySmall,
                        ),
                        onPressed: () {
                          _promptController.text = prompt;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Generation progress
                  BlocBuilder<EditorBloc, EditorState>(
                    builder: (context, state) {
                      if (state is EditorLoaded && state.isGeneratingApp) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: state.generationProgress),
                            const SizedBox(height: 8),
                            Text(
                              state.generationStatus ?? 'Generating...',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
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
                          final isConfigured = state is EditorLoaded && state.isOpenAIConfigured;
                          final isGenerating = state is EditorLoaded && state.isGeneratingApp;

                          if (!isConfigured) {
                            return FilledButton.icon(
                              onPressed: () => _showSettingsDialog(context),
                              icon: const Icon(Icons.key),
                              label: const Text('Configure API Key'),
                            );
                          }

                          return FilledButton.icon(
                            onPressed: isGenerating ? null : _generateApp,
                            icon: isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(isGenerating ? 'Generating...' : 'Generate App'),
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
    final path = await ProjectManagerService.instance.pickProjectLocation();
    if (path != null) {
      setState(() => _outputPath = path);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final bloc = context.read<EditorBloc>();
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const SettingsDialog(),
      ),
    );
  }

  Future<void> _generateApp() async {
    if (!_formKey.currentState!.validate() || _outputPath == null) {
      return;
    }

    context.read<EditorBloc>().add(GenerateAppFromPrompt(
      prompt: _promptController.text,
      projectName: _nameController.text,
      outputPath: _outputPath!,
      organization: _orgController.text,
    ));
  }
}

/// Import for settings dialog
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.settings, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Settings', style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // OpenAI Section
              Text('OpenAI API', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Enter your OpenAI API key to enable AI features.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Open OpenAI platform
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Get API key from OpenAI'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status
              BlocBuilder<EditorBloc, EditorState>(
                builder: (context, state) {
                  if (state is EditorLoaded && state.isOpenAIConfigured) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('OpenAI is configured and ready'),
                        ],
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('API key not configured'),
                      ],
                    ),
                  );
                },
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
                  FilledButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    if (_apiKeyController.text.isNotEmpty) {
      context.read<EditorBloc>().add(ConfigureOpenAI(
        apiKey: _apiKeyController.text,
      ));
    }
    Navigator.of(context).pop();
  }
}
