/// Built-in component definitions for the drag-and-drop palette
library;

import '../models/component_definition.dart';

/// All built-in components available in the palette
class BuiltinComponents {
  BuiltinComponents._();

  static List<ComponentDefinition> get all => [
        // Layout
        container,
        column,
        row,
        stack,
        wrap,
        center,
        padding,
        sizedBox,
        expanded,
        flexible,
        aspectRatio,
        // Content
        text,
        richText,
        icon,
        image,
        placeholder,
        divider,
        // Input
        textField,
        elevatedButton,
        textButton,
        outlinedButton,
        iconButton,
        floatingActionButton,
        checkbox,
        switchWidget,
        slider,
        dropdownButton,
        // Navigation
        scaffold,
        appBar,
        bottomNavigationBar,
        drawer,
        tabBar,
        navigationRail,
        // Feedback
        circularProgressIndicator,
        linearProgressIndicator,
        snackBar,
        // Scrolling
        listView,
        gridView,
        singleChildScrollView,
        // Decoration
        card,
        decoratedBox,
        clipRRect,
        opacity,
      ];

  // ============== LAYOUT COMPONENTS ==============

  static const container = ComponentDefinition(
    id: 'container',
    name: 'Container',
    category: ComponentCategory.layout,
    icon: '📦',
    description: 'A convenience widget combining common painting, positioning, and sizing widgets',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'width': CommonProperties.width,
      'height': CommonProperties.height,
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'padding': CommonProperties.padding,
      'margin': CommonProperties.margin,
      'alignment': CommonProperties.alignment,
      'borderRadius': CommonProperties.borderRadius,
    },
    codeTemplate: '''Container(
  {{#width}}width: {{width}},{{/width}}
  {{#height}}height: {{height}},{{/height}}
  {{#color}}color: {{color}},{{/color}}
  {{#padding}}padding: {{padding}},{{/padding}}
  {{#margin}}margin: {{margin}},{{/margin}}
  {{#alignment}}alignment: {{alignment}},{{/alignment}}
  {{#child}}child: {{child}},{{/child}}
)''',
    searchKeywords: ['box', 'wrapper', 'div'],
  );

  static const column = ComponentDefinition(
    id: 'column',
    name: 'Column',
    category: ComponentCategory.layout,
    icon: '↕️',
    description: 'A widget that displays its children in a vertical array',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'mainAxisAlignment': CommonProperties.mainAxisAlignment,
      'crossAxisAlignment': CommonProperties.crossAxisAlignment,
      'mainAxisSize': CommonProperties.mainAxisSize,
    },
    codeTemplate: '''Column(
  mainAxisAlignment: {{mainAxisAlignment}},
  crossAxisAlignment: {{crossAxisAlignment}},
  mainAxisSize: {{mainAxisSize}},
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['vertical', 'stack', 'list'],
  );

  static const row = ComponentDefinition(
    id: 'row',
    name: 'Row',
    category: ComponentCategory.layout,
    icon: '↔️',
    description: 'A widget that displays its children in a horizontal array',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'mainAxisAlignment': CommonProperties.mainAxisAlignment,
      'crossAxisAlignment': CommonProperties.crossAxisAlignment,
      'mainAxisSize': CommonProperties.mainAxisSize,
    },
    codeTemplate: '''Row(
  mainAxisAlignment: {{mainAxisAlignment}},
  crossAxisAlignment: {{crossAxisAlignment}},
  mainAxisSize: {{mainAxisSize}},
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['horizontal', 'inline'],
  );

  static const stack = ComponentDefinition(
    id: 'stack',
    name: 'Stack',
    category: ComponentCategory.layout,
    icon: '🗂️',
    description: 'A widget that positions its children relative to its edges',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'alignment': CommonProperties.alignment,
      'fit': PropertyDefinition(
        name: 'fit',
        displayName: 'Fit',
        type: PropertyType.string,
        group: 'Layout',
        defaultValue: 'StackFit.loose',
        options: ['StackFit.loose', 'StackFit.expand', 'StackFit.passthrough'],
      ),
    },
    codeTemplate: '''Stack(
  alignment: {{alignment}},
  fit: {{fit}},
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['layer', 'overlay', 'z-index'],
  );

  static const wrap = ComponentDefinition(
    id: 'wrap',
    name: 'Wrap',
    category: ComponentCategory.layout,
    icon: '🔄',
    description: 'A widget that displays children in multiple runs, wrapping as needed',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'spacing': PropertyDefinition(
        name: 'spacing',
        displayName: 'Spacing',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
      'runSpacing': PropertyDefinition(
        name: 'runSpacing',
        displayName: 'Run Spacing',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
      'alignment': PropertyDefinition(
        name: 'alignment',
        displayName: 'Alignment',
        type: PropertyType.string,
        group: 'Layout',
        defaultValue: 'WrapAlignment.start',
      ),
    },
    codeTemplate: '''Wrap(
  spacing: {{spacing}},
  runSpacing: {{runSpacing}},
  alignment: {{alignment}},
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['flex-wrap', 'flow'],
  );

  static const center = ComponentDefinition(
    id: 'center',
    name: 'Center',
    category: ComponentCategory.layout,
    icon: '🎯',
    description: 'Centers its child within itself',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'widthFactor': PropertyDefinition(
        name: 'widthFactor',
        displayName: 'Width Factor',
        type: PropertyType.number,
        group: 'Layout',
      ),
      'heightFactor': PropertyDefinition(
        name: 'heightFactor',
        displayName: 'Height Factor',
        type: PropertyType.number,
        group: 'Layout',
      ),
    },
    codeTemplate: '''Center(
  {{#widthFactor}}widthFactor: {{widthFactor}},{{/widthFactor}}
  {{#heightFactor}}heightFactor: {{heightFactor}},{{/heightFactor}}
  child: {{child}},
)''',
    searchKeywords: ['align', 'middle'],
  );

  static const padding = ComponentDefinition(
    id: 'padding',
    name: 'Padding',
    category: ComponentCategory.layout,
    icon: '⬜',
    description: 'Insets its child by the given padding',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'padding': CommonProperties.padding,
    },
    codeTemplate: '''Padding(
  padding: {{padding}},
  child: {{child}},
)''',
    searchKeywords: ['space', 'inset'],
  );

  static const sizedBox = ComponentDefinition(
    id: 'sizedBox',
    name: 'SizedBox',
    category: ComponentCategory.layout,
    icon: '📐',
    description: 'A box with a specified size',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'width': CommonProperties.width,
      'height': CommonProperties.height,
    },
    codeTemplate: '''SizedBox(
  {{#width}}width: {{width}},{{/width}}
  {{#height}}height: {{height}},{{/height}}
  {{#child}}child: {{child}},{{/child}}
)''',
    searchKeywords: ['size', 'fixed', 'spacer'],
  );

  static const expanded = ComponentDefinition(
    id: 'expanded',
    name: 'Expanded',
    category: ComponentCategory.layout,
    icon: '⬛',
    description: 'Expands a child of a Row, Column, or Flex',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'flex': PropertyDefinition(
        name: 'flex',
        displayName: 'Flex',
        type: PropertyType.integer,
        group: 'Layout',
        defaultValue: 1,
        min: 1,
      ),
    },
    codeTemplate: '''Expanded(
  flex: {{flex}},
  child: {{child}},
)''',
    searchKeywords: ['grow', 'fill'],
  );

  static const flexible = ComponentDefinition(
    id: 'flexible',
    name: 'Flexible',
    category: ComponentCategory.layout,
    icon: '📏',
    description: 'Controls how a child of a Row, Column, or Flex flexes',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'flex': PropertyDefinition(
        name: 'flex',
        displayName: 'Flex',
        type: PropertyType.integer,
        group: 'Layout',
        defaultValue: 1,
        min: 1,
      ),
      'fit': PropertyDefinition(
        name: 'fit',
        displayName: 'Fit',
        type: PropertyType.string,
        group: 'Layout',
        defaultValue: 'FlexFit.loose',
        options: ['FlexFit.tight', 'FlexFit.loose'],
      ),
    },
    codeTemplate: '''Flexible(
  flex: {{flex}},
  fit: {{fit}},
  child: {{child}},
)''',
    searchKeywords: ['grow', 'shrink'],
  );

  static const aspectRatio = ComponentDefinition(
    id: 'aspectRatio',
    name: 'AspectRatio',
    category: ComponentCategory.layout,
    icon: '🖼️',
    description: 'Sizes its child to a specific aspect ratio',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'aspectRatio': PropertyDefinition(
        name: 'aspectRatio',
        displayName: 'Aspect Ratio',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 1.0,
        min: 0.1,
      ),
    },
    codeTemplate: '''AspectRatio(
  aspectRatio: {{aspectRatio}},
  child: {{child}},
)''',
    searchKeywords: ['ratio', 'proportion'],
  );

  // ============== CONTENT COMPONENTS ==============

  static const text = ComponentDefinition(
    id: 'text',
    name: 'Text',
    category: ComponentCategory.content,
    icon: '📝',
    description: 'A run of styled text',
    acceptsChildren: false,
    properties: {
      'text': PropertyDefinition(
        name: 'data',
        displayName: 'Text',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Text',
        required: true,
      ),
      'fontSize': CommonProperties.fontSize,
      'fontWeight': CommonProperties.fontWeight,
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Text Color',
        type: PropertyType.color,
        group: 'Typography',
      ),
      'textAlign': CommonProperties.textAlign,
      'maxLines': PropertyDefinition(
        name: 'maxLines',
        displayName: 'Max Lines',
        type: PropertyType.integer,
        group: 'Typography',
        min: 1,
      ),
      'overflow': PropertyDefinition(
        name: 'overflow',
        displayName: 'Overflow',
        type: PropertyType.string,
        group: 'Typography',
        options: ['TextOverflow.clip', 'TextOverflow.fade', 'TextOverflow.ellipsis', 'TextOverflow.visible'],
      ),
    },
    codeTemplate: '''Text(
  '{{data}}',
  {{#fontSize}}style: TextStyle(fontSize: {{fontSize}}, {{#fontWeight}}fontWeight: {{fontWeight}},{{/fontWeight}} {{#color}}color: {{color}},{{/color}}),{{/fontSize}}
  {{#textAlign}}textAlign: {{textAlign}},{{/textAlign}}
  {{#maxLines}}maxLines: {{maxLines}},{{/maxLines}}
  {{#overflow}}overflow: {{overflow}},{{/overflow}}
)''',
    searchKeywords: ['label', 'string', 'typography'],
  );

  static const richText = ComponentDefinition(
    id: 'richText',
    name: 'RichText',
    category: ComponentCategory.content,
    icon: '✨',
    description: 'Text with multiple styles',
    acceptsChildren: false,
    properties: {
      'text': PropertyDefinition(
        name: 'text',
        displayName: 'Text',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Rich Text',
      ),
    },
    codeTemplate: '''RichText(
  text: TextSpan(
    text: '{{text}}',
    style: DefaultTextStyle.of(context).style,
  ),
)''',
    searchKeywords: ['styled', 'formatted'],
  );

  static const icon = ComponentDefinition(
    id: 'icon',
    name: 'Icon',
    category: ComponentCategory.content,
    icon: '⭐',
    description: 'A material design icon',
    acceptsChildren: false,
    properties: {
      'icon': PropertyDefinition(
        name: 'icon',
        displayName: 'Icon',
        type: PropertyType.icon,
        group: 'Content',
        defaultValue: 'Icons.star',
        required: true,
      ),
      'size': PropertyDefinition(
        name: 'size',
        displayName: 'Size',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 24.0,
        min: 8,
        max: 128,
      ),
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''Icon(
  {{icon}},
  {{#size}}size: {{size}},{{/size}}
  {{#color}}color: {{color}},{{/color}}
)''',
    searchKeywords: ['symbol', 'glyph'],
  );

  static const image = ComponentDefinition(
    id: 'image',
    name: 'Image',
    category: ComponentCategory.content,
    icon: '🖼️',
    description: 'A widget that displays an image',
    acceptsChildren: false,
    properties: {
      'src': PropertyDefinition(
        name: 'src',
        displayName: 'Source URL',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'https://via.placeholder.com/150',
        required: true,
      ),
      'width': CommonProperties.width,
      'height': CommonProperties.height,
      'fit': PropertyDefinition(
        name: 'fit',
        displayName: 'Fit',
        type: PropertyType.boxFit,
        group: 'Layout',
        defaultValue: 'BoxFit.cover',
      ),
    },
    codeTemplate: '''Image.network(
  '{{src}}',
  {{#width}}width: {{width}},{{/width}}
  {{#height}}height: {{height}},{{/height}}
  {{#fit}}fit: {{fit}},{{/fit}}
)''',
    searchKeywords: ['picture', 'photo'],
  );

  static const placeholder = ComponentDefinition(
    id: 'placeholder',
    name: 'Placeholder',
    category: ComponentCategory.content,
    icon: '⬜',
    description: 'A placeholder widget for missing content',
    acceptsChildren: false,
    properties: {
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
        defaultValue: 'Color(0xFF455A64)',
      ),
      'strokeWidth': PropertyDefinition(
        name: 'strokeWidth',
        displayName: 'Stroke Width',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 2.0,
      ),
    },
    codeTemplate: '''Placeholder(
  {{#color}}color: {{color}},{{/color}}
  {{#strokeWidth}}strokeWidth: {{strokeWidth}},{{/strokeWidth}}
)''',
    searchKeywords: ['empty', 'skeleton'],
  );

  static const divider = ComponentDefinition(
    id: 'divider',
    name: 'Divider',
    category: ComponentCategory.content,
    icon: '➖',
    description: 'A horizontal line separator',
    acceptsChildren: false,
    properties: {
      'height': PropertyDefinition(
        name: 'height',
        displayName: 'Height',
        type: PropertyType.number,
        group: 'Size',
        defaultValue: 16.0,
      ),
      'thickness': PropertyDefinition(
        name: 'thickness',
        displayName: 'Thickness',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 1.0,
      ),
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'indent': PropertyDefinition(
        name: 'indent',
        displayName: 'Indent',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
      'endIndent': PropertyDefinition(
        name: 'endIndent',
        displayName: 'End Indent',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
    },
    codeTemplate: '''Divider(
  {{#height}}height: {{height}},{{/height}}
  {{#thickness}}thickness: {{thickness}},{{/thickness}}
  {{#color}}color: {{color}},{{/color}}
  {{#indent}}indent: {{indent}},{{/indent}}
  {{#endIndent}}endIndent: {{endIndent}},{{/endIndent}}
)''',
    searchKeywords: ['line', 'separator', 'hr'],
  );

  // ============== INPUT COMPONENTS ==============

  static const textField = ComponentDefinition(
    id: 'textField',
    name: 'TextField',
    category: ComponentCategory.input,
    icon: '📝',
    description: 'A material design text input field',
    acceptsChildren: false,
    properties: {
      'labelText': PropertyDefinition(
        name: 'labelText',
        displayName: 'Label',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Label',
      ),
      'hintText': PropertyDefinition(
        name: 'hintText',
        displayName: 'Hint',
        type: PropertyType.string,
        group: 'Content',
      ),
      'obscureText': PropertyDefinition(
        name: 'obscureText',
        displayName: 'Obscure Text',
        type: PropertyType.boolean,
        group: 'Behavior',
        defaultValue: false,
      ),
      'enabled': PropertyDefinition(
        name: 'enabled',
        displayName: 'Enabled',
        type: PropertyType.boolean,
        group: 'Behavior',
        defaultValue: true,
      ),
      'maxLines': PropertyDefinition(
        name: 'maxLines',
        displayName: 'Max Lines',
        type: PropertyType.integer,
        group: 'Behavior',
        defaultValue: 1,
      ),
    },
    codeTemplate: '''TextField(
  decoration: InputDecoration(
    {{#labelText}}labelText: '{{labelText}}',{{/labelText}}
    {{#hintText}}hintText: '{{hintText}}',{{/hintText}}
  ),
  {{#obscureText}}obscureText: {{obscureText}},{{/obscureText}}
  {{#enabled}}enabled: {{enabled}},{{/enabled}}
  {{#maxLines}}maxLines: {{maxLines}},{{/maxLines}}
)''',
    searchKeywords: ['input', 'form', 'edit'],
  );

  static const elevatedButton = ComponentDefinition(
    id: 'elevatedButton',
    name: 'ElevatedButton',
    category: ComponentCategory.input,
    icon: '🔘',
    description: 'A material design elevated button',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'text': PropertyDefinition(
        name: 'text',
        displayName: 'Text',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Button',
      ),
      'enabled': PropertyDefinition(
        name: 'enabled',
        displayName: 'Enabled',
        type: PropertyType.boolean,
        group: 'Behavior',
        defaultValue: true,
      ),
    },
    codeTemplate: '''ElevatedButton(
  onPressed: {{#enabled}}() {}{{/enabled}}{{^enabled}}null{{/enabled}},
  child: Text('{{text}}'),
)''',
    searchKeywords: ['button', 'action', 'submit'],
  );

  static const textButton = ComponentDefinition(
    id: 'textButton',
    name: 'TextButton',
    category: ComponentCategory.input,
    icon: '🔗',
    description: 'A material design text button',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'text': PropertyDefinition(
        name: 'text',
        displayName: 'Text',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Button',
      ),
    },
    codeTemplate: '''TextButton(
  onPressed: () {},
  child: Text('{{text}}'),
)''',
    searchKeywords: ['button', 'link', 'flat'],
  );

  static const outlinedButton = ComponentDefinition(
    id: 'outlinedButton',
    name: 'OutlinedButton',
    category: ComponentCategory.input,
    icon: '⭕',
    description: 'A material design outlined button',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'text': PropertyDefinition(
        name: 'text',
        displayName: 'Text',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Button',
      ),
    },
    codeTemplate: '''OutlinedButton(
  onPressed: () {},
  child: Text('{{text}}'),
)''',
    searchKeywords: ['button', 'border'],
  );

  static const iconButton = ComponentDefinition(
    id: 'iconButton',
    name: 'IconButton',
    category: ComponentCategory.input,
    icon: '⚡',
    description: 'A button with an icon',
    acceptsChildren: false,
    properties: {
      'icon': PropertyDefinition(
        name: 'icon',
        displayName: 'Icon',
        type: PropertyType.icon,
        group: 'Content',
        defaultValue: 'Icons.add',
        required: true,
      ),
      'size': PropertyDefinition(
        name: 'iconSize',
        displayName: 'Size',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 24.0,
      ),
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''IconButton(
  icon: Icon({{icon}}),
  onPressed: () {},
  {{#iconSize}}iconSize: {{iconSize}},{{/iconSize}}
  {{#color}}color: {{color}},{{/color}}
)''',
    searchKeywords: ['button', 'action'],
  );

  static const floatingActionButton = ComponentDefinition(
    id: 'floatingActionButton',
    name: 'FloatingActionButton',
    category: ComponentCategory.input,
    icon: '➕',
    description: 'A floating action button',
    acceptsChildren: false,
    properties: {
      'icon': PropertyDefinition(
        name: 'icon',
        displayName: 'Icon',
        type: PropertyType.icon,
        group: 'Content',
        defaultValue: 'Icons.add',
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'mini': PropertyDefinition(
        name: 'mini',
        displayName: 'Mini',
        type: PropertyType.boolean,
        group: 'Appearance',
        defaultValue: false,
      ),
    },
    codeTemplate: '''FloatingActionButton(
  onPressed: () {},
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#mini}}mini: {{mini}},{{/mini}}
  child: Icon({{icon}}),
)''',
    searchKeywords: ['fab', 'action', 'add'],
  );

  static const checkbox = ComponentDefinition(
    id: 'checkbox',
    name: 'Checkbox',
    category: ComponentCategory.input,
    icon: '☑️',
    description: 'A material design checkbox',
    acceptsChildren: false,
    properties: {
      'value': PropertyDefinition(
        name: 'value',
        displayName: 'Value',
        type: PropertyType.boolean,
        group: 'State',
        defaultValue: false,
      ),
      'activeColor': PropertyDefinition(
        name: 'activeColor',
        displayName: 'Active Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''Checkbox(
  value: {{value}},
  onChanged: (value) {},
  {{#activeColor}}activeColor: {{activeColor}},{{/activeColor}}
)''',
    searchKeywords: ['check', 'toggle', 'boolean'],
  );

  static const switchWidget = ComponentDefinition(
    id: 'switch',
    name: 'Switch',
    category: ComponentCategory.input,
    icon: '🔘',
    description: 'A material design switch',
    acceptsChildren: false,
    properties: {
      'value': PropertyDefinition(
        name: 'value',
        displayName: 'Value',
        type: PropertyType.boolean,
        group: 'State',
        defaultValue: false,
      ),
      'activeColor': PropertyDefinition(
        name: 'activeColor',
        displayName: 'Active Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''Switch(
  value: {{value}},
  onChanged: (value) {},
  {{#activeColor}}activeColor: {{activeColor}},{{/activeColor}}
)''',
    searchKeywords: ['toggle', 'on-off'],
  );

  static const slider = ComponentDefinition(
    id: 'slider',
    name: 'Slider',
    category: ComponentCategory.input,
    icon: '🎚️',
    description: 'A material design slider',
    acceptsChildren: false,
    properties: {
      'value': PropertyDefinition(
        name: 'value',
        displayName: 'Value',
        type: PropertyType.number,
        group: 'State',
        defaultValue: 0.5,
        min: 0,
        max: 1,
      ),
      'min': PropertyDefinition(
        name: 'min',
        displayName: 'Min',
        type: PropertyType.number,
        group: 'Range',
        defaultValue: 0.0,
      ),
      'max': PropertyDefinition(
        name: 'max',
        displayName: 'Max',
        type: PropertyType.number,
        group: 'Range',
        defaultValue: 1.0,
      ),
      'divisions': PropertyDefinition(
        name: 'divisions',
        displayName: 'Divisions',
        type: PropertyType.integer,
        group: 'Range',
      ),
    },
    codeTemplate: '''Slider(
  value: {{value}},
  min: {{min}},
  max: {{max}},
  {{#divisions}}divisions: {{divisions}},{{/divisions}}
  onChanged: (value) {},
)''',
    searchKeywords: ['range', 'progress'],
  );

  static const dropdownButton = ComponentDefinition(
    id: 'dropdownButton',
    name: 'DropdownButton',
    category: ComponentCategory.input,
    icon: '🔽',
    description: 'A dropdown selection button',
    acceptsChildren: false,
    properties: {
      'hint': PropertyDefinition(
        name: 'hint',
        displayName: 'Hint',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Select...',
      ),
    },
    codeTemplate: '''DropdownButton<String>(
  hint: Text('{{hint}}'),
  items: [],
  onChanged: (value) {},
)''',
    searchKeywords: ['select', 'dropdown', 'picker'],
  );

  // ============== NAVIGATION COMPONENTS ==============

  static const scaffold = ComponentDefinition(
    id: 'scaffold',
    name: 'Scaffold',
    category: ComponentCategory.navigation,
    icon: '📱',
    description: 'The basic material design visual layout structure',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    namedSlots: ['appBar', 'body', 'floatingActionButton', 'drawer', 'bottomNavigationBar'],
    properties: {
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''Scaffold(
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#appBar}}appBar: {{appBar}},{{/appBar}}
  body: {{body}},
  {{#floatingActionButton}}floatingActionButton: {{floatingActionButton}},{{/floatingActionButton}}
  {{#drawer}}drawer: {{drawer}},{{/drawer}}
  {{#bottomNavigationBar}}bottomNavigationBar: {{bottomNavigationBar}},{{/bottomNavigationBar}}
)''',
    searchKeywords: ['page', 'screen', 'layout'],
  );

  static const appBar = ComponentDefinition(
    id: 'appBar',
    name: 'AppBar',
    category: ComponentCategory.navigation,
    icon: '📋',
    description: 'A material design app bar',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    namedSlots: ['leading', 'title', 'actions'],
    properties: {
      'title': PropertyDefinition(
        name: 'title',
        displayName: 'Title',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'App Bar',
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'centerTitle': PropertyDefinition(
        name: 'centerTitle',
        displayName: 'Center Title',
        type: PropertyType.boolean,
        group: 'Layout',
        defaultValue: false,
      ),
      'elevation': PropertyDefinition(
        name: 'elevation',
        displayName: 'Elevation',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 4.0,
        min: 0,
        max: 24,
      ),
    },
    codeTemplate: '''AppBar(
  title: Text('{{title}}'),
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#centerTitle}}centerTitle: {{centerTitle}},{{/centerTitle}}
  {{#elevation}}elevation: {{elevation}},{{/elevation}}
)''',
    searchKeywords: ['header', 'toolbar', 'navigation'],
  );

  static const bottomNavigationBar = ComponentDefinition(
    id: 'bottomNavigationBar',
    name: 'BottomNavigationBar',
    category: ComponentCategory.navigation,
    icon: '⬇️',
    description: 'A material design bottom navigation bar',
    acceptsChildren: false,
    properties: {
      'currentIndex': PropertyDefinition(
        name: 'currentIndex',
        displayName: 'Current Index',
        type: PropertyType.integer,
        group: 'State',
        defaultValue: 0,
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'selectedItemColor': PropertyDefinition(
        name: 'selectedItemColor',
        displayName: 'Selected Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''BottomNavigationBar(
  currentIndex: {{currentIndex}},
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#selectedItemColor}}selectedItemColor: {{selectedItemColor}},{{/selectedItemColor}}
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
  onTap: (index) {},
)''',
    searchKeywords: ['tabs', 'bottom', 'nav'],
  );

  static const drawer = ComponentDefinition(
    id: 'drawer',
    name: 'Drawer',
    category: ComponentCategory.navigation,
    icon: '📑',
    description: 'A material design drawer',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'elevation': PropertyDefinition(
        name: 'elevation',
        displayName: 'Elevation',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 16.0,
      ),
    },
    codeTemplate: '''Drawer(
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#elevation}}elevation: {{elevation}},{{/elevation}}
  child: {{child}},
)''',
    searchKeywords: ['menu', 'side', 'navigation'],
  );

  static const tabBar = ComponentDefinition(
    id: 'tabBar',
    name: 'TabBar',
    category: ComponentCategory.navigation,
    icon: '📑',
    description: 'A material design tab bar',
    acceptsChildren: false,
    properties: {
      'isScrollable': PropertyDefinition(
        name: 'isScrollable',
        displayName: 'Scrollable',
        type: PropertyType.boolean,
        group: 'Behavior',
        defaultValue: false,
      ),
      'indicatorColor': PropertyDefinition(
        name: 'indicatorColor',
        displayName: 'Indicator Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''TabBar(
  {{#isScrollable}}isScrollable: {{isScrollable}},{{/isScrollable}}
  {{#indicatorColor}}indicatorColor: {{indicatorColor}},{{/indicatorColor}}
  tabs: [
    Tab(text: 'Tab 1'),
    Tab(text: 'Tab 2'),
    Tab(text: 'Tab 3'),
  ],
)''',
    searchKeywords: ['tabs', 'segments'],
  );

  static const navigationRail = ComponentDefinition(
    id: 'navigationRail',
    name: 'NavigationRail',
    category: ComponentCategory.navigation,
    icon: '📍',
    description: 'A material design navigation rail',
    acceptsChildren: false,
    properties: {
      'selectedIndex': PropertyDefinition(
        name: 'selectedIndex',
        displayName: 'Selected Index',
        type: PropertyType.integer,
        group: 'State',
        defaultValue: 0,
      ),
      'extended': PropertyDefinition(
        name: 'extended',
        displayName: 'Extended',
        type: PropertyType.boolean,
        group: 'Appearance',
        defaultValue: false,
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''NavigationRail(
  selectedIndex: {{selectedIndex}},
  {{#extended}}extended: {{extended}},{{/extended}}
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  destinations: [
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
    NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
    NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
  ],
  onDestinationSelected: (index) {},
)''',
    searchKeywords: ['side', 'vertical', 'navigation'],
  );

  // ============== FEEDBACK COMPONENTS ==============

  static const circularProgressIndicator = ComponentDefinition(
    id: 'circularProgressIndicator',
    name: 'CircularProgressIndicator',
    category: ComponentCategory.feedback,
    icon: '🔄',
    description: 'A circular progress indicator',
    acceptsChildren: false,
    properties: {
      'value': PropertyDefinition(
        name: 'value',
        displayName: 'Value',
        type: PropertyType.number,
        group: 'State',
        description: 'Leave empty for indeterminate',
        min: 0,
        max: 1,
      ),
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'strokeWidth': PropertyDefinition(
        name: 'strokeWidth',
        displayName: 'Stroke Width',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 4.0,
      ),
    },
    codeTemplate: '''CircularProgressIndicator(
  {{#value}}value: {{value}},{{/value}}
  {{#color}}color: {{color}},{{/color}}
  {{#strokeWidth}}strokeWidth: {{strokeWidth}},{{/strokeWidth}}
)''',
    searchKeywords: ['loading', 'spinner', 'progress'],
  );

  static const linearProgressIndicator = ComponentDefinition(
    id: 'linearProgressIndicator',
    name: 'LinearProgressIndicator',
    category: ComponentCategory.feedback,
    icon: '📊',
    description: 'A linear progress indicator',
    acceptsChildren: false,
    properties: {
      'value': PropertyDefinition(
        name: 'value',
        displayName: 'Value',
        type: PropertyType.number,
        group: 'State',
        description: 'Leave empty for indeterminate',
        min: 0,
        max: 1,
      ),
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'minHeight': PropertyDefinition(
        name: 'minHeight',
        displayName: 'Min Height',
        type: PropertyType.number,
        group: 'Size',
        defaultValue: 4.0,
      ),
    },
    codeTemplate: '''LinearProgressIndicator(
  {{#value}}value: {{value}},{{/value}}
  {{#color}}color: {{color}},{{/color}}
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
  {{#minHeight}}minHeight: {{minHeight}},{{/minHeight}}
)''',
    searchKeywords: ['loading', 'progress', 'bar'],
  );

  static const snackBar = ComponentDefinition(
    id: 'snackBar',
    name: 'SnackBar',
    category: ComponentCategory.feedback,
    icon: '💬',
    description: 'A lightweight message at the bottom of screen',
    acceptsChildren: false,
    properties: {
      'content': PropertyDefinition(
        name: 'content',
        displayName: 'Content',
        type: PropertyType.string,
        group: 'Content',
        defaultValue: 'Message',
      ),
      'actionLabel': PropertyDefinition(
        name: 'actionLabel',
        displayName: 'Action Label',
        type: PropertyType.string,
        group: 'Content',
      ),
      'backgroundColor': PropertyDefinition(
        name: 'backgroundColor',
        displayName: 'Background Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
    },
    codeTemplate: '''SnackBar(
  content: Text('{{content}}'),
  {{#actionLabel}}action: SnackBarAction(label: '{{actionLabel}}', onPressed: () {}),{{/actionLabel}}
  {{#backgroundColor}}backgroundColor: {{backgroundColor}},{{/backgroundColor}}
)''',
    searchKeywords: ['toast', 'message', 'notification'],
  );

  // ============== SCROLLING COMPONENTS ==============

  static const listView = ComponentDefinition(
    id: 'listView',
    name: 'ListView',
    category: ComponentCategory.scrolling,
    icon: '📜',
    description: 'A scrollable list of widgets',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'padding': CommonProperties.padding,
      'scrollDirection': PropertyDefinition(
        name: 'scrollDirection',
        displayName: 'Scroll Direction',
        type: PropertyType.string,
        group: 'Layout',
        defaultValue: 'Axis.vertical',
        options: ['Axis.vertical', 'Axis.horizontal'],
      ),
      'shrinkWrap': PropertyDefinition(
        name: 'shrinkWrap',
        displayName: 'Shrink Wrap',
        type: PropertyType.boolean,
        group: 'Layout',
        defaultValue: false,
      ),
    },
    codeTemplate: '''ListView(
  {{#padding}}padding: {{padding}},{{/padding}}
  {{#scrollDirection}}scrollDirection: {{scrollDirection}},{{/scrollDirection}}
  {{#shrinkWrap}}shrinkWrap: {{shrinkWrap}},{{/shrinkWrap}}
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['scroll', 'list', 'items'],
  );

  static const gridView = ComponentDefinition(
    id: 'gridView',
    name: 'GridView',
    category: ComponentCategory.scrolling,
    icon: '📱',
    description: 'A scrollable grid of widgets',
    acceptsChildren: true,
    acceptsMultipleChildren: true,
    allowedChildren: ['any'],
    properties: {
      'crossAxisCount': PropertyDefinition(
        name: 'crossAxisCount',
        displayName: 'Cross Axis Count',
        type: PropertyType.integer,
        group: 'Layout',
        defaultValue: 2,
        min: 1,
      ),
      'mainAxisSpacing': PropertyDefinition(
        name: 'mainAxisSpacing',
        displayName: 'Main Axis Spacing',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
      'crossAxisSpacing': PropertyDefinition(
        name: 'crossAxisSpacing',
        displayName: 'Cross Axis Spacing',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 0.0,
      ),
      'childAspectRatio': PropertyDefinition(
        name: 'childAspectRatio',
        displayName: 'Child Aspect Ratio',
        type: PropertyType.number,
        group: 'Layout',
        defaultValue: 1.0,
      ),
      'padding': CommonProperties.padding,
      'shrinkWrap': PropertyDefinition(
        name: 'shrinkWrap',
        displayName: 'Shrink Wrap',
        type: PropertyType.boolean,
        group: 'Layout',
        defaultValue: false,
      ),
    },
    codeTemplate: '''GridView.count(
  crossAxisCount: {{crossAxisCount}},
  {{#mainAxisSpacing}}mainAxisSpacing: {{mainAxisSpacing}},{{/mainAxisSpacing}}
  {{#crossAxisSpacing}}crossAxisSpacing: {{crossAxisSpacing}},{{/crossAxisSpacing}}
  {{#childAspectRatio}}childAspectRatio: {{childAspectRatio}},{{/childAspectRatio}}
  {{#padding}}padding: {{padding}},{{/padding}}
  {{#shrinkWrap}}shrinkWrap: {{shrinkWrap}},{{/shrinkWrap}}
  children: [
    {{#children}}{{.}},{{/children}}
  ],
)''',
    searchKeywords: ['grid', 'tiles', 'gallery'],
  );

  static const singleChildScrollView = ComponentDefinition(
    id: 'singleChildScrollView',
    name: 'SingleChildScrollView',
    category: ComponentCategory.scrolling,
    icon: '📃',
    description: 'A scrollable widget that contains a single child',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'scrollDirection': PropertyDefinition(
        name: 'scrollDirection',
        displayName: 'Scroll Direction',
        type: PropertyType.string,
        group: 'Layout',
        defaultValue: 'Axis.vertical',
        options: ['Axis.vertical', 'Axis.horizontal'],
      ),
      'padding': CommonProperties.padding,
    },
    codeTemplate: '''SingleChildScrollView(
  {{#scrollDirection}}scrollDirection: {{scrollDirection}},{{/scrollDirection}}
  {{#padding}}padding: {{padding}},{{/padding}}
  child: {{child}},
)''',
    searchKeywords: ['scroll', 'overflow'],
  );

  // ============== DECORATION COMPONENTS ==============

  static const card = ComponentDefinition(
    id: 'card',
    name: 'Card',
    category: ComponentCategory.decoration,
    icon: '🃏',
    description: 'A material design card',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'elevation': PropertyDefinition(
        name: 'elevation',
        displayName: 'Elevation',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 1.0,
        min: 0,
        max: 24,
      ),
      'margin': CommonProperties.margin,
      'borderRadius': PropertyDefinition(
        name: 'borderRadius',
        displayName: 'Border Radius',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 4.0,
      ),
    },
    codeTemplate: '''Card(
  {{#color}}color: {{color}},{{/color}}
  {{#elevation}}elevation: {{elevation}},{{/elevation}}
  {{#margin}}margin: {{margin}},{{/margin}}
  {{#borderRadius}}shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular({{borderRadius}})),{{/borderRadius}}
  child: {{child}},
)''',
    searchKeywords: ['box', 'surface', 'panel'],
  );

  static const decoratedBox = ComponentDefinition(
    id: 'decoratedBox',
    name: 'DecoratedBox',
    category: ComponentCategory.decoration,
    icon: '🎨',
    description: 'A widget that paints a decoration',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'color': PropertyDefinition(
        name: 'color',
        displayName: 'Color',
        type: PropertyType.color,
        group: 'Appearance',
      ),
      'borderRadius': CommonProperties.borderRadius,
    },
    codeTemplate: '''DecoratedBox(
  decoration: BoxDecoration(
    {{#color}}color: {{color}},{{/color}}
    {{#borderRadius}}borderRadius: {{borderRadius}},{{/borderRadius}}
  ),
  child: {{child}},
)''',
    searchKeywords: ['background', 'border', 'style'],
  );

  static const clipRRect = ComponentDefinition(
    id: 'clipRRect',
    name: 'ClipRRect',
    category: ComponentCategory.decoration,
    icon: '⬜',
    description: 'A widget that clips with rounded corners',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'borderRadius': PropertyDefinition(
        name: 'borderRadius',
        displayName: 'Border Radius',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 8.0,
      ),
    },
    codeTemplate: '''ClipRRect(
  borderRadius: BorderRadius.circular({{borderRadius}}),
  child: {{child}},
)''',
    searchKeywords: ['clip', 'round', 'corners'],
  );

  static const opacity = ComponentDefinition(
    id: 'opacity',
    name: 'Opacity',
    category: ComponentCategory.decoration,
    icon: '👻',
    description: 'A widget that adjusts opacity',
    acceptsChildren: true,
    acceptsMultipleChildren: false,
    allowedChildren: ['any'],
    properties: {
      'opacity': PropertyDefinition(
        name: 'opacity',
        displayName: 'Opacity',
        type: PropertyType.number,
        group: 'Appearance',
        defaultValue: 1.0,
        min: 0,
        max: 1,
      ),
    },
    codeTemplate: '''Opacity(
  opacity: {{opacity}},
  child: {{child}},
)''',
    searchKeywords: ['transparency', 'fade', 'alpha'],
  );
}
