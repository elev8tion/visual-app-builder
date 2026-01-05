import 'dart:async';
import 'dart:html' as html;

/// Service that manages communication between the Editor and Preview IFrame
/// Uses window.postMessage for cross-origin communication
class PreviewBridgeService {
  static PreviewBridgeService? _instance;
  static PreviewBridgeService get instance => _instance ??= PreviewBridgeService._();

  PreviewBridgeService._();

  StreamSubscription? _messageSubscription;
  final _widgetSelectedController = StreamController<WidgetSelectionEvent>.broadcast();
  final _propertyChangedController = StreamController<PropertyChangeEvent>.broadcast();
  final _previewStateController = StreamController<PreviewStateEvent>.broadcast();

  html.IFrameElement? _previewFrame;

  /// Stream of widget selection events from the preview
  Stream<WidgetSelectionEvent> get onWidgetSelected => _widgetSelectedController.stream;

  /// Stream of property change events (from preview to editor)
  Stream<PropertyChangeEvent> get onPropertyChanged => _propertyChangedController.stream;

  /// Stream of preview state events (ready, error, hot reload, etc.)
  Stream<PreviewStateEvent> get onPreviewState => _previewStateController.stream;

  /// Initialize the bridge and start listening for messages
  void initialize() {
    _messageSubscription?.cancel();
    _messageSubscription = html.window.onMessage.listen(_handleMessage);
  }

  /// Set the preview IFrame element for sending messages
  void setPreviewFrame(html.IFrameElement frame) {
    _previewFrame = frame;
  }

  /// Handle incoming messages from the preview
  void _handleMessage(html.MessageEvent event) {
    if (event.data is! Map) return;

    final data = Map<String, dynamic>.from(event.data as Map);
    final type = data['type'] as String?;

    switch (type) {
      case 'widgetSelected':
        _handleWidgetSelected(data);
        break;
      case 'widgetHovered':
        _handleWidgetHovered(data);
        break;
      case 'propertyChanged':
        _handlePropertyChanged(data);
        break;
      case 'previewReady':
        _previewStateController.add(PreviewStateEvent.ready());
        break;
      case 'previewError':
        _previewStateController.add(PreviewStateEvent.error(
          data['error'] as String? ?? 'Unknown error',
        ));
        break;
      case 'hotReloadComplete':
        _previewStateController.add(PreviewStateEvent.hotReloadComplete());
        break;
      case 'widgetTree':
        _handleWidgetTree(data);
        break;
    }
  }

  void _handleWidgetSelected(Map<String, dynamic> data) {
    final widgetId = data['widgetId'] as String?;
    final widgetType = data['widgetType'] as String?;
    final properties = data['properties'] as Map<String, dynamic>?;
    final bounds = data['bounds'] as Map<String, dynamic>?;

    if (widgetId != null) {
      _widgetSelectedController.add(WidgetSelectionEvent(
        widgetId: widgetId,
        widgetType: widgetType,
        properties: properties ?? {},
        bounds: bounds != null
            ? WidgetBounds(
                x: (bounds['x'] as num).toDouble(),
                y: (bounds['y'] as num).toDouble(),
                width: (bounds['width'] as num).toDouble(),
                height: (bounds['height'] as num).toDouble(),
              )
            : null,
      ));
    }
  }

  void _handleWidgetHovered(Map<String, dynamic> data) {
    // Handle hover events for preview highlighting
  }

  void _handlePropertyChanged(Map<String, dynamic> data) {
    final widgetId = data['widgetId'] as String?;
    final propertyName = data['propertyName'] as String?;
    final newValue = data['newValue'];

    if (widgetId != null && propertyName != null) {
      _propertyChangedController.add(PropertyChangeEvent(
        widgetId: widgetId,
        propertyName: propertyName,
        newValue: newValue,
      ));
    }
  }

  void _handleWidgetTree(Map<String, dynamic> data) {
    // Handle full widget tree updates from preview
    final tree = data['tree'] as List<dynamic>?;
    if (tree != null) {
      _previewStateController.add(PreviewStateEvent.widgetTreeUpdate(tree));
    }
  }

  // ============================================
  // Editor -> Preview Commands
  // ============================================

  /// Send a message to the preview IFrame
  void _sendToPreview(Map<String, dynamic> message) {
    _previewFrame?.contentWindow?.postMessage(message, '*');
  }

  /// Enable or disable widget selection mode in preview
  void setSelectionMode(bool enabled) {
    _sendToPreview({
      'type': 'setSelectionMode',
      'enabled': enabled,
    });
  }

  /// Highlight a specific widget in the preview
  void highlightWidget(String widgetId) {
    _sendToPreview({
      'type': 'highlightWidget',
      'widgetId': widgetId,
    });
  }

  /// Clear all widget highlights
  void clearHighlights() {
    _sendToPreview({'type': 'clearHighlights'});
  }

  /// Update a widget property in the preview
  void updateProperty(String widgetId, String propertyName, dynamic value) {
    _sendToPreview({
      'type': 'updateProperty',
      'widgetId': widgetId,
      'propertyName': propertyName,
      'value': value,
    });
  }

  /// Request hot reload
  void requestHotReload() {
    _sendToPreview({'type': 'requestHotReload'});
  }

  /// Request the full widget tree from preview
  void requestWidgetTree() {
    _sendToPreview({'type': 'requestWidgetTree'});
  }

  /// Navigate to a specific screen/route in preview
  void navigateTo(String route) {
    _sendToPreview({
      'type': 'navigate',
      'route': route,
    });
  }

  /// Set device simulation parameters
  void setDeviceSimulation({
    required double width,
    required double height,
    double? pixelRatio,
    String? platform,
  }) {
    _sendToPreview({
      'type': 'setDeviceSimulation',
      'width': width,
      'height': height,
      if (pixelRatio != null) 'pixelRatio': pixelRatio,
      if (platform != null) 'platform': platform,
    });
  }

  /// Dispose the service
  void dispose() {
    _messageSubscription?.cancel();
    _widgetSelectedController.close();
    _propertyChangedController.close();
    _previewStateController.close();
    _instance = null;
  }

  /// Reset the singleton (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Event when a widget is selected in the preview
class WidgetSelectionEvent {
  final String widgetId;
  final String? widgetType;
  final Map<String, dynamic> properties;
  final WidgetBounds? bounds;

  WidgetSelectionEvent({
    required this.widgetId,
    this.widgetType,
    this.properties = const {},
    this.bounds,
  });
}

/// Widget bounds in the preview coordinate system
class WidgetBounds {
  final double x;
  final double y;
  final double width;
  final double height;

  WidgetBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Event when a property is changed in the preview
class PropertyChangeEvent {
  final String widgetId;
  final String propertyName;
  final dynamic newValue;

  PropertyChangeEvent({
    required this.widgetId,
    required this.propertyName,
    required this.newValue,
  });
}

/// Preview state events
class PreviewStateEvent {
  final PreviewState state;
  final String? error;
  final List<dynamic>? widgetTree;

  PreviewStateEvent._({
    required this.state,
    this.error,
    this.widgetTree,
  });

  factory PreviewStateEvent.ready() => PreviewStateEvent._(state: PreviewState.ready);

  factory PreviewStateEvent.error(String error) =>
      PreviewStateEvent._(state: PreviewState.error, error: error);

  factory PreviewStateEvent.hotReloadComplete() =>
      PreviewStateEvent._(state: PreviewState.hotReloadComplete);

  factory PreviewStateEvent.widgetTreeUpdate(List<dynamic> tree) =>
      PreviewStateEvent._(state: PreviewState.widgetTreeUpdate, widgetTree: tree);
}

enum PreviewState {
  ready,
  error,
  hotReloadComplete,
  widgetTreeUpdate,
}
