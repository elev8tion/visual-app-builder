/// Project Templates
///
/// Pre-built templates for common Flutter app types.
/// Each template includes file structure, dependencies, and state management setup.
library project_templates;

/// Available project templates
enum ProjectTemplate {
  blank,
  counter,
  todo,
  ecommerce,
  social,
  dashboard,
}

/// State management options
enum StateManagement {
  none,
  provider,
  riverpod,
  bloc,
  getx,
}

extension StateManagementExtension on StateManagement {
  String get displayName {
    switch (this) {
      case StateManagement.none:
        return 'None';
      case StateManagement.provider:
        return 'Provider';
      case StateManagement.riverpod:
        return 'Riverpod';
      case StateManagement.bloc:
        return 'BLoC';
      case StateManagement.getx:
        return 'GetX';
    }
  }

  List<String> get dependencies {
    switch (this) {
      case StateManagement.none:
        return [];
      case StateManagement.provider:
        return ['provider: ^6.1.1'];
      case StateManagement.riverpod:
        return ['flutter_riverpod: ^2.4.9', 'riverpod_annotation: ^2.3.3'];
      case StateManagement.bloc:
        return ['flutter_bloc: ^8.1.3', 'equatable: ^2.0.5'];
      case StateManagement.getx:
        return ['get: ^4.6.6'];
    }
  }
}

/// Template configuration
class ProjectTemplateConfig {
  final ProjectTemplate template;
  final String name;
  final String description;
  final String icon;
  final List<String> features;
  final Map<String, String> fileTemplates;
  final List<String> dependencies;
  final StateManagement defaultStateManagement;

  const ProjectTemplateConfig({
    required this.template,
    required this.name,
    required this.description,
    required this.icon,
    required this.features,
    required this.fileTemplates,
    required this.dependencies,
    required this.defaultStateManagement,
  });
}

/// Project templates registry
class ProjectTemplates {
  static const Map<ProjectTemplate, ProjectTemplateConfig> templates = {
    ProjectTemplate.blank: ProjectTemplateConfig(
      template: ProjectTemplate.blank,
      name: 'Blank',
      description: 'Empty Flutter project with basic structure',
      icon: '📄',
      features: ['Basic app structure', 'Material 3 theme'],
      fileTemplates: {},
      dependencies: [],
      defaultStateManagement: StateManagement.none,
    ),
    ProjectTemplate.counter: ProjectTemplateConfig(
      template: ProjectTemplate.counter,
      name: 'Counter',
      description: 'Classic counter app with state management',
      icon: '🔢',
      features: ['Counter logic', 'State management', 'Clean architecture'],
      fileTemplates: _counterTemplates,
      dependencies: [],
      defaultStateManagement: StateManagement.provider,
    ),
    ProjectTemplate.todo: ProjectTemplateConfig(
      template: ProjectTemplate.todo,
      name: 'Todo List',
      description: 'Task management app with CRUD operations',
      icon: '✅',
      features: ['Task CRUD', 'Local storage', 'Categories', 'Due dates'],
      fileTemplates: _todoTemplates,
      dependencies: ['shared_preferences: ^2.2.2'],
      defaultStateManagement: StateManagement.provider,
    ),
    ProjectTemplate.ecommerce: ProjectTemplateConfig(
      template: ProjectTemplate.ecommerce,
      name: 'E-Commerce',
      description: 'Online store with products, cart, and checkout',
      icon: '🛒',
      features: ['Product catalog', 'Shopping cart', 'Checkout flow', 'User auth placeholder'],
      fileTemplates: _ecommerceTemplates,
      dependencies: ['cached_network_image: ^3.3.0'],
      defaultStateManagement: StateManagement.provider,
    ),
    ProjectTemplate.social: ProjectTemplateConfig(
      template: ProjectTemplate.social,
      name: 'Social Feed',
      description: 'Social media app with posts and profiles',
      icon: '📱',
      features: ['Feed', 'Posts', 'Profiles', 'Likes & Comments'],
      fileTemplates: _socialTemplates,
      dependencies: ['cached_network_image: ^3.3.0'],
      defaultStateManagement: StateManagement.provider,
    ),
    ProjectTemplate.dashboard: ProjectTemplateConfig(
      template: ProjectTemplate.dashboard,
      name: 'Dashboard',
      description: 'Analytics dashboard with charts and data',
      icon: '📊',
      features: ['Charts', 'Statistics cards', 'Data tables', 'Responsive layout'],
      fileTemplates: _dashboardTemplates,
      dependencies: ['fl_chart: ^0.66.0'],
      defaultStateManagement: StateManagement.provider,
    ),
  };

  /// Get template by type
  static ProjectTemplateConfig? getTemplate(ProjectTemplate template) {
    return templates[template];
  }

  /// Get all templates as list
  static List<ProjectTemplateConfig> get all => templates.values.toList();
}

// ==================== Counter Templates ====================

const Map<String, String> _counterTemplates = {
  'lib/main.dart': _counterMainDart,
  'lib/features/counter/counter_screen.dart': _counterScreen,
  'lib/features/counter/counter_provider.dart': _counterProvider,
};

const String _counterMainDart = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/counter/counter_provider.dart';
import 'features/counter/counter_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: MaterialApp(
        title: 'Counter App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const CounterScreen(),
      ),
    );
  }
}
''';

const String _counterScreen = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'counter_provider.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            Consumer<CounterProvider>(
              builder: (context, counter, child) {
                return Text(
                  '\${counter.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => context.read<CounterProvider>().increment(),
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => context.read<CounterProvider>().decrement(),
            tooltip: 'Decrement',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
''';

const String _counterProvider = '''
import 'package:flutter/foundation.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
''';

// ==================== Todo Templates ====================

const Map<String, String> _todoTemplates = {
  'lib/main.dart': _todoMainDart,
  'lib/models/todo.dart': _todoModel,
  'lib/features/todo/todo_screen.dart': _todoScreen,
  'lib/features/todo/todo_provider.dart': _todoProvider,
};

const String _todoMainDart = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/todo/todo_provider.dart';
import 'features/todo/todo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: MaterialApp(
        title: 'Todo App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const TodoScreen(),
      ),
    );
  }
}
''';

const String _todoModel = '''
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
''';

const String _todoScreen = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'todo_provider.dart';
import '../../models/todo.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          if (provider.todos.isEmpty) {
            return const Center(
              child: Text('No tasks yet. Add one!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.todos.length,
            itemBuilder: (context, index) {
              final todo = provider.todos[index];
              return _TodoCard(todo: todo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Task title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<TodoProvider>().addTodo(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final Todo todo;

  const _TodoCard({required this.todo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (value) {
            context.read<TodoProvider>().toggleTodo(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id);
          },
        ),
      ),
    );
  }
}
''';

const String _todoProvider = '''
import 'package:flutter/foundation.dart';
import '../../models/todo.dart';

class TodoProvider extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  void addTodo(String title, {String? description, DateTime? dueDate}) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    _todos.add(todo);
    notifyListeners();
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
      notifyListeners();
    }
  }

  void deleteTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void updateTodo(String id, {String? title, String? description}) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        title: title,
        description: description,
      );
      notifyListeners();
    }
  }
}
''';

// ==================== E-commerce Templates ====================

const Map<String, String> _ecommerceTemplates = {
  'lib/main.dart': _ecommerceMainDart,
  'lib/models/product.dart': _productModel,
  'lib/features/home/home_screen.dart': _ecommerceHomeScreen,
  'lib/features/cart/cart_screen.dart': _cartScreen,
  'lib/features/cart/cart_provider.dart': _cartProvider,
};

const String _ecommerceMainDart = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/cart/cart_provider.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Shop App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
''';

const String _productModel = '''
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

// Sample products
final sampleProducts = [
  Product(
    id: '1',
    name: 'Wireless Headphones',
    description: 'High-quality wireless headphones with noise cancellation',
    price: 199.99,
    imageUrl: 'https://picsum.photos/200?random=1',
    category: 'Electronics',
  ),
  Product(
    id: '2',
    name: 'Smart Watch',
    description: 'Fitness tracking smartwatch with heart rate monitor',
    price: 299.99,
    imageUrl: 'https://picsum.photos/200?random=2',
    category: 'Electronics',
  ),
  Product(
    id: '3',
    name: 'Running Shoes',
    description: 'Comfortable running shoes for all terrains',
    price: 89.99,
    imageUrl: 'https://picsum.photos/200?random=3',
    category: 'Sports',
  ),
];
''';

const String _ecommerceHomeScreen = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text('\${cart.itemCount}'),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sampleProducts.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: sampleProducts[index]);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\\\$\${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      context.read<CartProvider>().addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added \${product.name} to cart')),
                      );
                    },
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
''';

const String _cartScreen = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('\\\$\${item.product.price.toStringAsFixed(2)} x \${item.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => cart.decrementQuantity(item.product.id),
                          ),
                          Text('\${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => cart.addToCart(item.product),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \\\$\${cart.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    FilledButton(
                      onPressed: () {
                        // Checkout logic
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
''';

const String _cartProvider = '''
import 'package:flutter/foundation.dart';
import '../../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(
    0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  void addToCart(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
''';

// ==================== Social Templates ====================

const Map<String, String> _socialTemplates = {
  'lib/main.dart': _socialMainDart,
};

const String _socialMainDart = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FeedScreen(),
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User \${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                          Text('\${index + 1}h ago', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('This is a sample post #\${index + 1}. Social feed template with basic structure.'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Post'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
''';

// ==================== Dashboard Templates ====================

const Map<String, String> _dashboardTemplates = {
  'lib/main.dart': _dashboardMainDart,
};

const String _dashboardMainDart = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Revenue', value: '\\\$12,345', icon: Icons.attach_money, color: Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Users', value: '1,234', icon: Icons.people, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Orders', value: '567', icon: Icons.shopping_cart, color: Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Growth', value: '+12%', icon: Icons.trending_up, color: Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text('\${index + 1}')),
                    title: Text('Activity item \${index + 1}'),
                    subtitle: Text('\${index + 1} hours ago'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: const Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Center(
                child: Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
            ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
            ListTile(leading: Icon(Icons.analytics), title: Text('Analytics')),
            ListTile(leading: Icon(Icons.people), title: Text('Users')),
            ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
''';
