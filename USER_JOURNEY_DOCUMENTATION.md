# Visual App Builder - Complete User Journey Documentation

> A systematic walkthrough of building an app from start to finish with Visual App Builder

---

## Table of Contents

1. [App Entry & Initialization](#1-app-entry--initialization)
2. [Project Creation Flow](#2-project-creation-flow)
3. [AI App Generation Flow](#3-ai-app-generation-flow)
4. [Code Editing Flow](#4-code-editing-flow)
5. [Preview/Run Flow](#5-previewrun-flow)
6. [Git Integration Flow](#6-git-integration-flow)
7. [Build/Export Flow](#7-buildexport-flow)
8. [Architecture Summary](#8-architecture-summary)
9. [Key Code Files Reference](#9-key-code-files-reference)

---

## 1. App Entry & Initialization

### User Experience
When you launch Visual App Builder, you see the main editor interface with a loading state until the default project is loaded.

### Technical Flow

```
App Launch → main.dart → EditorScreen → BlocProvider<EditorBloc> → LoadProject('default')
```

### Key Files

| File | Purpose | Location |
|------|---------|----------|
| `main.dart` | App entry point, MaterialApp setup | `/lib/main.dart:1-35` |
| `app_theme.dart` | Dark theme configuration | `/lib/core/theme/app_theme.dart` |
| `editor_bloc.dart` | Central state management | `/lib/bloc/editor/editor_bloc.dart` |

### Services Initialized

The EditorBloc initializes these services on startup:

```dart
// In EditorBloc constructor
- ProjectManagerService    // Project loading/creation
- AIAgentService          // AI code generation
- TerminalService         // Flutter command execution
- GitService              // Version control
- AppGenerationService    // Full app generation
- ConfigService           // Settings management
- OpenAIService           // OpenAI API integration
- BidirectionalSyncManager // Widget ↔ Code sync
```

### Backend Server Startup

```dart
// packages/backend/lib/server.dart:36-42
final terminalService = TerminalServiceImpl();
final configService = ConfigServiceImpl();
final projectManager = ProjectManagerImpl(terminalService, configService);
final gitService = GitServiceImpl();
final terminalWebSocket = TerminalWebSocket(terminalService);
```

---

## 2. Project Creation Flow

### User Experience

1. Click "New Project" button in toolbar
2. **New Project Dialog** appears with:
   - Project name field (validated: lowercase, alphanumeric)
   - Organization field (default: `com.example`)
   - Template selection (Blank, Counter, etc.)
   - State management choice (Provider, Riverpod, BLoC)
   - Output path selector
3. Click "Create" → Progress shown → Project opens in editor

### Technical Flow

```
NewProjectDialog → CreateProject Event → EditorBloc → ProjectManagerService
                                                           ↓
                                                   TerminalService.createProject()
                                                           ↓
                                                   flutter create (SSE stream)
                                                           ↓
                                                   Project loaded into editor
```

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `new_project_dialog.dart` | Creation UI form | `/lib/features/editor/widgets/new_project_dialog.dart:1-150+` |
| `project_handler.dart` | Backend REST handler | `/packages/backend/lib/handlers/project_handler.dart:17-68` |
| `project_manager_impl.dart` | Project creation logic | `/packages/backend/lib/services/project_manager_impl.dart` |

### BLoC Event

```dart
class CreateProject extends EditorEvent {
  final String name;
  final String organization;
  final ProjectTemplate template;
  final StateManagement stateManagement;
  final String outputPath;
}
```

### API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/projects/create` | Creates Flutter project (SSE stream) |
| POST | `/api/projects/open` | Opens existing project |
| GET | `/api/projects/recent` | Recent projects list |
| GET | `/api/projects/default-directory` | Default projects directory |

### Data Models

```dart
// packages/shared/lib/models/project.dart

class FlutterProject {
  final String name;
  final String path;
  final String? description;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final List<String> platforms;
}

class RecentProject {
  final String name;
  final String path;
  final DateTime lastOpened;
}
```

---

## 3. AI App Generation Flow

### User Experience

1. Click "AI Generate" button
2. **AI App Generator Dialog** opens:
   - Project name and organization
   - Output directory
   - Prompt textarea (describe your app)
3. Enter prompt like: *"Create a todo list app with categories, due dates, and dark mode"*
4. Watch real-time progress through 8 generation phases
5. Generated project opens automatically

### Technical Flow

```
AIAppGeneratorDialog → GenerateApp Event → EditorBloc → AppGenerationService
                                                              ↓
                                                    Phase 1: Parse prompt → AppSpec
                                                    Phase 2: Plan → flutter create
                                                    Phase 3: Generate Models
                                                    Phase 4: Generate Screens
                                                    Phase 5: Generate Navigation
                                                    Phase 6: Generate State
                                                    Phase 7: Generate Main
                                                    Phase 8: Write Files
                                                              ↓
                                                    Project loaded into editor
```

### 8 Generation Phases

| Phase | Progress | Description |
|-------|----------|-------------|
| Parsing | 5-15% | Parse prompt into AppSpec using OpenAI |
| Planning | 20-25% | Create base Flutter project |
| Models | 30-40% | Generate Dart model classes |
| Screens | 40-65% | Generate screen widgets |
| Navigation | 65-75% | Generate routing/navigation |
| State | 75-85% | Generate state management |
| Main | 85-90% | Update main.dart |
| Complete | 90-100% | Write all files, finish |

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `ai_app_generator_dialog.dart` | Generator UI | `/lib/features/editor/widgets/ai_app_generator_dialog.dart:1-150+` |
| `app_generation_service.dart` | Generation orchestration | `/lib/core/services/app_generation_service.dart:1-200+` |
| `openai_service.dart` | OpenAI API integration | `/lib/core/services/openai_service.dart` |

### BLoC Event

```dart
class GenerateApp extends EditorEvent {
  final String prompt;
  final String projectName;
  final String outputPath;
  final String? organization;
}
```

### Data Models

```dart
// lib/core/models/app_spec.dart

class AppSpec {
  final String name;
  final String description;
  final List<ScreenSpec> screens;
  final List<ModelSpec> models;
  final List<String> features;
  final String stateManagement;
  final ThemeSpec? theme;
  final NavigationSpec? navigation;
}

class ScreenSpec {
  final String name;
  final String description;
  final String route;
  final ScreenType type;  // regular, list, detail, form, dashboard
  final List<WidgetSpec> widgets;
  final List<ActionSpec> actions;
  final bool isInitial;
}

class ModelSpec {
  final String name;
  final String description;
  final List<FieldSpec> fields;
  final List<String> relationships;

  String toDartClass();  // Generates actual Dart class code
}

class GenerationProgress {
  final GenerationPhase phase;
  final double progress;  // 0.0-1.0
  final String message;
  final String? generatedFile;
  final String? error;
}
```

---

## 4. Code Editing Flow

### User Experience

The editor has a multi-panel layout:

```
┌─────────────────────────────────────────────────────────────┐
│              Top Toolbar (buttons, file name)                │
├────────────────┬─────────────────────┬──────────────────────┤
│  Left Panel    │    Center Panel     │    Right Panel       │
│  ─────────     │    ────────────     │    ──────────        │
│  • File Tree   │  • Code Editor      │  • Properties Panel  │
│  • Widget Tree │    OR               │    (selected widget) │
│  • Git Panel   │  • Preview          │                      │
│                │    OR               │  • AI Agent Chat     │
│                │  • Split View       │    (code assistant)  │
└────────────────┴─────────────────────┴──────────────────────┘
```

### File Navigation

1. **File Explorer Panel** - Browse project files
2. Click file → Loads into code editor
3. Files saved automatically (with debounce) or manually

### Widget Editing

1. **Widget Tree Panel** - Visual hierarchy of widgets
2. Click widget → Selected in code + Properties panel
3. **Properties Panel** - Edit widget properties
4. Changes sync bidirectionally (code ↔ tree ↔ properties)

### AI Code Assistant

1. **Agent Chat Panel** - Ask AI for code help
2. Describe what you want → AI generates code
3. Insert generated code at cursor position

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `editor_screen.dart` | Main editor layout | `/lib/features/editor/editor_screen.dart:90-300+` |
| `code_editor_panel.dart` | Dart code editor | `/lib/features/editor/widgets/code_editor_panel.dart:1-100+` |
| `file_explorer_panel.dart` | File tree navigation | `/lib/features/editor/widgets/file_explorer_panel.dart` |
| `widget_tree_panel.dart` | Widget hierarchy view | `/lib/features/editor/widgets/widget_tree_panel.dart` |
| `properties_panel.dart` | Widget property editor | `/lib/features/editor/widgets/properties_panel.dart` |
| `agent_chat_panel.dart` | AI code assistant | `/lib/features/editor/widgets/agent_chat_panel.dart` |

### BLoC Events

```dart
// File Operations
class SelectProjectFile extends EditorEvent { final ProjectFile file; }
class UpdateCode extends EditorEvent { final String code; }

// Widget Operations
class SelectWidget extends EditorEvent { final WidgetNode? widget; }
class SelectWidgetByLine extends EditorEvent { final int lineNumber; }
class UpdateProperty extends EditorEvent {
  final String widgetId;
  final String propertyName;
  final dynamic value;
}

// Code Manipulation
class InsertWidgetCode extends EditorEvent {
  final String widgetCode;
  final InsertPosition position;
}
class DeleteSelectedWidget extends EditorEvent {}
class WrapSelectedWidget extends EditorEvent {
  final String wrapperWidget;
  final Map<String, dynamic>? properties;
}

// History
class Undo extends EditorEvent {}
class Redo extends EditorEvent {}
```

### Data Models

```dart
// lib/core/models/widget_node.dart

class WidgetNode {
  final String id;
  final String type;     // Scaffold, Container, Text, etc.
  final String name;
  final Map<String, dynamic> properties;
  final List<WidgetNode> children;
  final String? parentId;
  final bool isExpanded;

  IconData get icon;     // Returns icon for widget type
}

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  final bool isExpanded;
}

enum ViewMode { preview, code, split }
enum PanelType { widgetTree, properties, agent }
```

---

## 5. Preview/Run Flow

### User Experience

1. Click "Run" button in toolbar
2. Select target device (Chrome, iOS Simulator, Android Emulator, etc.)
3. Watch build progress in terminal panel
4. App launches in device/browser
5. Make code changes → Click "Hot Reload" → Changes appear instantly

### Technical Flow

```
Run Button → RunProject Event → EditorBloc → TerminalService.runProject()
                                                    ↓
                                            flutter run -d <device>
                                                    ↓
                                            WebSocket streams output
                                                    ↓
                                            Preview Panel shows logs
```

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `terminal_service.dart` | Command execution | `/lib/core/services/terminal_service.dart:1-150+` |
| `terminal_handler.dart` | Backend API handler | `/packages/backend/lib/handlers/terminal_handler.dart:35-80+` |
| `preview_panel.dart` | Terminal output display | `/lib/features/editor/widgets/preview_panel.dart` |
| `terminal_websocket.dart` | Real-time streaming | `/packages/backend/lib/websocket/terminal_websocket.dart` |

### BLoC Events

```dart
class RunProject extends EditorEvent { final String? device; }
class HotReload extends EditorEvent {}
class HotRestart extends EditorEvent {}
class StopRunningApp extends EditorEvent {}
```

### Terminal Service Methods

```dart
Stream<String> runProject({
  required String projectPath,
  String? device,
  bool verbose = false,
});

Stream<String> hotReload();    // 'r' command
Stream<String> hotRestart();   // 'R' command
Stream<void> stop();           // 'q' command

Stream<String> pubGet({required String projectPath});
Stream<String> clean({required String projectPath});
```

### API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/terminal/run` | Run Flutter project (SSE) |
| POST | `/api/terminal/hot-reload` | Trigger hot reload |
| POST | `/api/terminal/hot-restart` | Trigger hot restart |
| POST | `/api/terminal/stop` | Stop running app |
| GET | `/api/terminal/devices` | List available devices |
| GET | `/api/terminal/status` | Current process status |

### WebSocket

| Endpoint | Purpose |
|----------|---------|
| `ws://localhost:8080/ws/terminal` | Real-time terminal output streaming |

---

## 6. Git Integration Flow

### User Experience

1. **Source Control Panel** shows:
   - Current branch name
   - Changed files (modified, added, deleted, untracked)
   - Staged vs. unstaged files
2. Click file → Stage/unstage
3. Enter commit message → Click "Commit"
4. Click "Push" to push to remote
5. Click "Pull" to pull changes

### Technical Flow

```
Source Control Panel → GitStageFile Event → EditorBloc → GitService
                                                              ↓
                                                        git add <file>
                                                        git commit -m "..."
                                                        git push
```

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `git_service.dart` | Git operations | `/lib/core/services/git_service.dart:1-107` |
| `git_handler.dart` | Backend API handler | `/packages/backend/lib/handlers/git_handler.dart:1-100+` |
| `source_control_panel.dart` | Git UI panel | `/lib/features/editor/widgets/source_control_panel.dart` |

### BLoC Events

```dart
class GitCheckStatus extends EditorEvent {}
class GitStageFile extends EditorEvent { final String filePath; }
class GitUnstageFile extends EditorEvent { final String filePath; }
class GitCommit extends EditorEvent { final String message; }
class GitPush extends EditorEvent {}
class GitPull extends EditorEvent {}
```

### Git Service Methods

```dart
Future<bool> isGitRepository();
Future<void> init();                          // git init
Future<GitStatus> getStatus();                // git status --porcelain
Future<void> stageFile(String path);          // git add
Future<void> unstageFile(String path);        // git reset HEAD
Future<void> commit(String message);          // git commit -m
Future<void> push();                          // git push
Future<void> pull();                          // git pull
```

### API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/git/status?path=...` | Get git status |
| POST | `/api/git/stage` | Stage files |
| POST | `/api/git/stage-all` | Stage all files |
| POST | `/api/git/unstage` | Unstage files |
| POST | `/api/git/commit` | Commit with message |
| POST | `/api/git/push` | Push to remote |
| POST | `/api/git/pull` | Pull from remote |
| GET | `/api/git/history` | Commit history |
| POST | `/api/git/init` | Initialize repo |
| GET | `/api/git/branches` | All branches |
| POST | `/api/git/checkout` | Switch branch |
| POST | `/api/git/create-branch` | Create new branch |

### Data Models

```dart
class GitStatus {
  final String branch;
  final List<GitFileStatus> files;
}

class GitFileStatus {
  final String path;
  final String status;   // 'M' modified, 'A' added, 'D' deleted, '??' untracked
  final bool isStaged;
}
```

---

## 7. Build/Export Flow

### User Experience

1. Click "Build" in toolbar
2. Select platform:
   - Android (APK / App Bundle)
   - iOS (Archive)
   - Web (Static files)
   - macOS / Windows / Linux
3. Select mode: Debug / Release
4. Watch build progress
5. Output file location shown when complete

### Technical Flow

```
Build Button → BuildProject Event → EditorBloc → TerminalService.buildProject()
                                                          ↓
                                                  flutter build <platform>
                                                          ↓
                                                  SSE streams progress
                                                          ↓
                                                  Output path displayed
```

### Key Files

| File | Purpose |
|------|---------|
| `terminal_service.dart` | Build command execution |
| `terminal_handler.dart` | Build API endpoint |

### BLoC Event

```dart
class BuildProject extends EditorEvent {
  final String platform;   // apk, ios, web, macos, windows, linux
  final bool release;
  final bool verbose;
}
```

### Build Command

```dart
Stream<String> buildProject({
  required String projectPath,
  required String platform,
  bool release = false,
  bool verbose = false,
});
```

### Build Outputs

| Platform | Debug Output | Release Output |
|----------|--------------|----------------|
| Android | `build/app/outputs/flutter-apk/app-debug.apk` | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | `build/ios/iphoneos/Runner.app` | `.ipa` (requires signing) |
| Web | `build/web/` | `build/web/` (minified) |
| macOS | `build/macos/Build/Products/Debug/` | `build/macos/Build/Products/Release/` |
| Windows | `build/windows/runner/Debug/` | `build/windows/runner/Release/` |
| Linux | `build/linux/x64/debug/` | `build/linux/x64/release/` |

### API Endpoint

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/terminal/build` | Build for platform (SSE stream) |

---

## 8. Architecture Summary

### Overall Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Web (PWA)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Code Editor │  │   Preview   │  │    AI Chat Panel    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                           │                                  │
│              HTTP/REST + WebSocket (API Client)              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 Dart Shelf Backend Server                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Terminal API │  │   File API   │  │   Git API    │       │
│  │ (flutter run)│  │ (read/write) │  │(commit/push) │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                           │                                  │
│              dart:io (File, Process, Directory)              │
└─────────────────────────────────────────────────────────────┘
```

### BLoC Pattern

```
UI Widget → Event → EditorBloc → Service → External (API/File/Process)
                         ↓
                     State Update
                         ↓
                    BlocBuilder rebuilds UI
```

### Key State Properties (EditorLoaded)

```dart
class EditorLoaded extends EditorState {
  // Project
  final String projectName;
  final String projectPath;
  final FlutterProject? project;

  // Files
  final List<FileNode> files;
  final ProjectFile? currentFile;
  final String currentCode;

  // Widgets
  final List<WidgetNode> widgetTree;
  final WidgetNode? selectedWidget;

  // UI State
  final ViewMode viewMode;           // code, preview, split
  final bool showWidgetTree;
  final bool showProperties;
  final bool showAgent;

  // Process State
  final bool isAppRunning;
  final bool isGeneratingApp;
  final GenerationProgress? generationProgress;

  // History
  final bool canUndo;
  final bool canRedo;
  final bool isDirty;

  // Git
  final GitStatus? gitStatus;
}
```

---

## 9. Key Code Files Reference

### Core Application

| File | Purpose |
|------|---------|
| `/lib/main.dart` | App entry point |
| `/lib/bloc/editor/editor_bloc.dart` | Central state management |
| `/lib/features/editor/editor_screen.dart` | Main editor UI layout |

### Services (Frontend)

| File | Purpose |
|------|---------|
| `/lib/core/services/app_generation_service.dart` | AI app generation |
| `/lib/core/services/openai_service.dart` | OpenAI API integration |
| `/lib/core/services/ai_agent_service.dart` | AI code assistant |
| `/lib/core/services/terminal_service.dart` | Flutter command execution |
| `/lib/core/services/project_manager_service.dart` | Project management |
| `/lib/core/services/git_service.dart` | Git operations |
| `/lib/core/services/config_service.dart` | Configuration |
| `/lib/core/services/bidirectional_sync_manager.dart` | Widget ↔ Code sync |
| `/lib/core/services/api_client.dart` | Backend HTTP/WebSocket client |

### UI Widgets

| File | Purpose |
|------|---------|
| `/lib/features/editor/widgets/top_toolbar.dart` | Toolbar buttons |
| `/lib/features/editor/widgets/file_explorer_panel.dart` | File tree |
| `/lib/features/editor/widgets/widget_tree_panel.dart` | Widget hierarchy |
| `/lib/features/editor/widgets/properties_panel.dart` | Property editor |
| `/lib/features/editor/widgets/code_editor_panel.dart` | Code editor |
| `/lib/features/editor/widgets/preview_panel.dart` | Terminal/preview |
| `/lib/features/editor/widgets/agent_chat_panel.dart` | AI assistant |
| `/lib/features/editor/widgets/source_control_panel.dart` | Git panel |
| `/lib/features/editor/widgets/new_project_dialog.dart` | Create project |
| `/lib/features/editor/widgets/ai_app_generator_dialog.dart` | AI generator |

### Backend Server

| File | Purpose |
|------|---------|
| `/packages/backend/bin/server.dart` | Server entry point |
| `/packages/backend/lib/server.dart` | Server setup & routing |
| `/packages/backend/lib/handlers/project_handler.dart` | Project API |
| `/packages/backend/lib/handlers/terminal_handler.dart` | Terminal API |
| `/packages/backend/lib/handlers/git_handler.dart` | Git API |
| `/packages/backend/lib/handlers/files_handler.dart` | File API |
| `/packages/backend/lib/handlers/config_handler.dart` | Config API |
| `/packages/backend/lib/services/project_manager_impl.dart` | Project impl |
| `/packages/backend/lib/services/terminal_service_impl.dart` | Terminal impl |
| `/packages/backend/lib/services/git_service_impl.dart` | Git impl |
| `/packages/backend/lib/websocket/terminal_websocket.dart` | WebSocket streaming |

### Shared Models

| File | Purpose |
|------|---------|
| `/packages/shared/lib/models/project.dart` | FlutterProject, ProjectFile |
| `/packages/shared/lib/models/app_spec.dart` | AppSpec, ScreenSpec, ModelSpec |
| `/lib/core/models/widget_node.dart` | WidgetNode, FileNode |
| `/lib/core/models/widget_selection.dart` | WidgetSelection, WidgetTreeNode |
| `/lib/core/models/app_spec.dart` | GenerationProgress, GenerationPhase |

### Configuration & Scripts

| File | Purpose |
|------|---------|
| `/scripts/start_dev.sh` | Start backend + frontend for development |
| `/scripts/start_backend.sh` | Start backend server only |
| `/scripts/build_prod.sh` | Build production distribution |
| `/dist/run.sh` | Run production server |
| `/web/manifest.json` | PWA manifest |
| `/web/service_worker.js` | PWA offline caching |

---

## Quick Reference: Complete User Journey

```
1. LAUNCH APP
   └── main.dart → EditorScreen → EditorBloc initialized

2. CREATE PROJECT
   └── New Project Dialog → CreateProject Event → flutter create

3. OR GENERATE WITH AI
   └── AI Generator Dialog → GenerateApp Event → 8-phase generation

4. EDIT CODE
   ├── File Explorer → Select file → Code loads
   ├── Widget Tree → Select widget → Properties panel
   ├── Properties Panel → Edit values → Code updates
   └── AI Agent Panel → Describe code → AI generates

5. RUN APP
   └── Run Button → RunProject Event → flutter run → WebSocket streams output

6. HOT RELOAD
   └── Save code → Hot Reload button → 'r' command → App updates

7. COMMIT CHANGES
   ├── Source Control → See changed files
   ├── Stage files → Commit message
   └── Commit → Push to remote

8. BUILD FOR RELEASE
   └── Build Button → Select platform → flutter build → Output file
```

---

*Document generated for Visual App Builder v1.0*
*Architecture: Flutter Web PWA + Dart Shelf Backend*
