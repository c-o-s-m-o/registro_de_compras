import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(SupermarketApp());
  });
}

class SupermarketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Compras',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange[600],
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[300]),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/shoppingList': (context) => ShoppingListScreen(),
        '/purchasesList': (context) => PurchasesListScreen(),
        '/about': (context) => AboutScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Compras'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/icons/icon.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 5,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/assets/icons/icon.png',
                      width: 100,
                      height: 100,
                      color: Colors.orange[600],
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildActionButton(
                    context,
                    'Iniciar Nova Compra',
                    Icons.add_shopping_cart_sharp,
                    () => Navigator.pushNamed(context, '/shoppingList'),
                  ),
                  SizedBox(height: 20),
                  _buildActionButton(
                    context,
                    'Ver Compras Realizadas',
                    Icons.history,
                    () => Navigator.pushNamed(context, '/purchasesList'),
                  ),
                  SizedBox(height: 20),
                  _buildActionButton(
                    context,
                    'Sobre o App',
                    Icons.info,
                    () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        elevation: 5,
      ),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<Map<String, dynamic>> _items = [];
  double _total = 0.0;
  late Database _database;
  final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  List<Map<String, dynamic>> _supermarkets = [];
  int? _selectedSupermarketId;
  TextEditingController _supermarketController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'shopping_list.db');

    _database = await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE supermarkets(id INTEGER PRIMARY KEY, name TEXT)",
        );
        await db.execute(
          "CREATE TABLE purchases(id INTEGER PRIMARY KEY, supermarket_id INTEGER, date TEXT, total REAL)",
        );
        await db.execute(
          "CREATE TABLE items(id INTEGER PRIMARY KEY, name TEXT, quantity INTEGER, price REAL, hidden INTEGER, purchase_id INTEGER)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await db.execute("ALTER TABLE items ADD COLUMN purchase_id INTEGER");
        }
      },
      version: 1,
    );
    await _loadItems();
    await _loadSupermarkets();
  }

  Future<void> _loadItems() async {
    try {
      final List<Map<String, dynamic>> items = await _database.query(
        'items',
        where: 'purchase_id IS NULL',
      );
      setState(() {
        _items = items;
        _filteredItems = items;
        _calculateTotal();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar itens: $e')),
      );
    }
  }

  Future<void> _loadSupermarkets() async {
    try {
      final List<Map<String, dynamic>> supermarkets = await _database.query(
        'supermarkets',
      );
      setState(() {
        _supermarkets = supermarkets;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar supermercados: $e')),
      );
    }
  }

  void _calculateTotal() {
    _total = _items.where((item) => item['hidden'] == 0).fold(0.0, (sum, item) {
      return sum + (item['quantity'] * item['price']);
    });
  }

  Future<void> _addItem(String name, int quantity, double price) async {
    try {
      await _database.insert('items', {
        'name': name,
        'quantity': quantity,
        'price': price,
        'hidden': 0,
        'purchase_id': null,
      });
      await _loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar item: $e')),
      );
    }
  }

  Future<void> _editItem(
    int id,
    String name,
    int quantity,
    double price,
  ) async {
    try {
      await _database.update(
        'items',
        {'name': name, 'quantity': quantity, 'price': price},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar item: $e')),
      );
    }
  }

  Future<void> _toggleItemVisibility(int id, int hidden) async {
    try {
      await _database.update(
        'items',
        {'hidden': hidden},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alternar visibilidade: $e')),
      );
    }
  }

  Future<void> _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir este item?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Excluir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _database.delete(
          'items',
          where: 'id = ?',
          whereArgs: [id],
        );
        await _loadItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir item: $e')),
        );
      }
    }
  }

  Future<void> _finalizePurchase(String date) async {
    if (_selectedSupermarketId == null && _supermarketController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione ou insira um supermercado')),
      );
      return;
    }

    int supermarketId;
    if (_selectedSupermarketId == null) {
      try {
        supermarketId = await _database.insert('supermarkets', {
          'name': _supermarketController.text,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar supermercado: $e')),
        );
        return;
      }
    } else {
      supermarketId = _selectedSupermarketId!;
    }

    try {
      int purchaseId = await _database.insert('purchases', {
        'supermarket_id': supermarketId,
        'date': date,
        'total': _total,
      });

      for (var item in _items) {
        await _database.update(
          'items',
          {'purchase_id': purchaseId},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar compra: $e')),
      );
    }
  }

  void _showFinalizeDialog() {
    TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Finalizar Compra', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: _selectedSupermarketId,
                  hint: Text('Selecione um supermercado', style: TextStyle(color: Colors.grey[300])),
                  items: _supermarkets.map((supermarket) {
                    return DropdownMenuItem<int>(
                      value: supermarket['id'],
                      child: Text(
                        supermarket['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupermarketId = value;
                    });
                  },
                  dropdownColor: Colors.grey[800],
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: _supermarketController,
                  decoration: InputDecoration(
                    labelText: 'Ou insira um novo supermercado',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                  ),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(labelText: 'Data', labelStyle: TextStyle(color: Colors.grey[300])),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancelar', style: TextStyle(color: Colors.orange[600])),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                ),
                child: Text('Salvar', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _finalizePurchase(dateController.text);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showItemDialog({
    int? id,
    String name = '',
    int quantity = 1,
    double price = 0.0,
  }) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController quantityController = TextEditingController(text: quantity.toString());
    TextEditingController priceController = TextEditingController(text: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(price));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Adicionar Item' : 'Editar Item', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: TextStyle(color: Colors.grey[300]),
                prefixIcon: Icon(Icons.shopping_basket, color: Colors.orange[600]),
              ),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                labelStyle: TextStyle(color: Colors.grey[300]),
                prefixIcon: Icon(Icons.format_list_numbered, color: Colors.orange[600]),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Preço',
                labelStyle: TextStyle(color: Colors.grey[300]),
                prefixIcon: Icon(Icons.attach_money, color: Colors.orange[600]),
              ),
              inputFormatters: [CurrencyInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(color: Colors.orange[600])),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: Text(id == null ? 'Adicionar' : 'Salvar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              String itemName = nameController.text.trim();
              int itemQuantity = int.tryParse(quantityController.text) ?? 0;
              double itemPrice = (double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) / 100;

              if (itemName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('O nome do item não pode estar vazio')),
                );
                return;
              }

              if (itemQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('A quantidade deve ser maior que zero')),
                );
                return;
              }

              if (itemPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('O preço deve ser maior que zero')),
                );
                return;
              }

              if (id == null) {
                _addItem(itemName, itemQuantity, itemPrice);
              } else {
                _editItem(id, itemName, itemQuantity, itemPrice);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _items
          .where((item) => item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Compra'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar itens...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[300]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _filterItems,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ShoppingListItem(
                    item: item,
                    onToggleVisibility: (id) => _toggleItemVisibility(id, item['hidden'] == 1 ? 0 : 1),
                    onEdit: (id) => _showItemDialog(
                      id: item['id'],
                      name: item['name'],
                      quantity: item['quantity'],
                      price: item['price'],
                    ),
                    onDelete: _deleteItem,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total: ${_currencyFormatter.format(_total)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showFinalizeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 5,
                    ),
                    child: Text(
                      'Finalizar Compra',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[600],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showItemDialog(),
      ),
    );
  }
}

class ShoppingListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onToggleVisibility;
  final Function(int) onEdit;
  final Function(int) onDelete;

  ShoppingListItem({
    required this.item,
    required this.onToggleVisibility,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          item['name'],
          style: TextStyle(
            color: item['hidden'] == 1 ? Colors.grey : Colors.white,
          ),
        ),
        subtitle: Text(
          'Qtd: ${item['quantity']} - ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item['price'])}',
          style: TextStyle(
            color: item['hidden'] == 1 ? Colors.grey : Colors.grey[300],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item['hidden'] == 1 ? Icons.visibility_off : Icons.visibility,
                color: item['hidden'] == 1 ? Colors.grey : Colors.orange[600],
              ),
              onPressed: () => onToggleVisibility(item['id']),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange[600]),
              onPressed: () => onEdit(item['id']),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade600),
              onPressed: () => onDelete(item['id']),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchasesListScreen extends StatefulWidget {
  @override
  _PurchasesListScreenState createState() => _PurchasesListScreenState();
}
class _PurchasesListScreenState extends State<PurchasesListScreen> {
  late Database _database;
  List<Map<String, dynamic>> _purchases = [];
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPurchases = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'shopping_list.db');

    _database = await openDatabase(path);
    await _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      final List<Map<String, dynamic>> purchases = await _database.rawQuery('''
        SELECT purchases.id, supermarkets.name AS supermarket, purchases.date, purchases.total
        FROM purchases
        INNER JOIN supermarkets ON purchases.supermarket_id = supermarkets.id
        ORDER BY purchases.date DESC
      ''');
      setState(() {
        _purchases = purchases;
        _filteredPurchases = purchases;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar compras: $e')),
      );
    }
  }

  void _filterPurchases(String query) {
    setState(() {
      _filteredPurchases = _purchases
          .where((purchase) => purchase['supermarket']
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compras Realizadas'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar compras...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[300]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _filterPurchases,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = _filteredPurchases[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        purchase['supermarket'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        'Data: ${purchase['date']} - Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(purchase['total'])}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                      ),
                      onTap: () async {
                        try {
                          final List<Map<String, dynamic>> items = await _database.query(
                            'items',
                            where: 'purchase_id = ?',
                            whereArgs: [purchase['id']],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PurchasedItemsScreen(purchase: purchase, items: items),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao carregar itens: $e')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchasedItemsScreen extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final List<Map<String, dynamic>> items;

  PurchasedItemsScreen({required this.purchase, required this.items});

  @override
  Widget build(BuildContext context) {
    int totalItems = items.length;
    double mostExpensiveItemPrice = items.map((item) => item['price']).reduce((a, b) => a > b ? a : b);
    Map<String, dynamic> mostExpensiveItem = items.firstWhere((item) => item['price'] == mostExpensiveItemPrice);

    return Scaffold(
      appBar: AppBar(
        title: Text('Itens Comprados'),
      ),
      backgroundColor: Colors.grey[900],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supermercado: ${purchase['supermarket']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Data: ${purchase['date']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Total da Compra: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(purchase['total'])}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Resumo da Compra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatisticItem(
                      icon: Icons.shopping_basket,
                      label: 'Total de Itens',
                      value: totalItems.toString(),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildStatisticItem(
                      icon: Icons.attach_money,
                      label: 'Item Mais Caro',
                      value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(mostExpensiveItem['price']),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Itens Comprados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              ...items.map((item) {
                return Card(
                  color: Colors.grey[800],
                  margin: EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantidade: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                        Text(
                          'Preço Unitário: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item['price'])}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                        Text(
                          'Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item['quantity'] * item['price'])}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticItem({required IconData icon, required String label, required String value}) {
    return Card(
      color: Colors.grey[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.orange[600]),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(newText) / 100;

    String formatted = _formatter.format(value).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sobre o App'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.shopping_cart,
                  size: 80,
                  color: Colors.orange[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Registro de Compras',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildSectionTitle('A Ideia:'),
              _buildSectionText(
                'Este app foi criado para tornar suas compras no supermercado mais rápidas e eficientes. '
                'Muitas vezes, precisamos anotar os itens que precisamos comprar antes de sair de casa, '
                'mas esquecemos de algo ou perdemos tempo somando os valores no celular ou na calculadora. '
                'Além disso, quando vamos com dinheiro contado, pode ser constrangedor descobrir no caixa '
                'que a compra ultrapassou o valor que temos.',
              ),
              SizedBox(height: 20),
              _buildSectionTitle('Como o App Ajuda:'),
              _buildSectionText('Com o Registro de Compras, você pode:'),
              SizedBox(height: 10),
              _buildFeatureItem('Anotar os itens que precisa comprar antes de sair de casa.'),
              _buildFeatureItem('Registrar o preço e a quantidade de cada item diretamente no app.'),
              _buildFeatureItem('Calcular automaticamente o total da compra, evitando surpresas no caixa.'),
              _buildFeatureItem('Visualizar compras anteriores para planejar melhor suas próximas idas ao supermercado.'),
              SizedBox(height: 20),
              _buildSectionTitle('Criador:'),
              _buildSectionText('Desenvolvido por [C-o-s-m-o]'),
              SizedBox(height: 20),
              _buildSectionTitle('Versão:'),
              _buildSectionText('1.0.0'),
              SizedBox(height: 20),
              Center(
                child: Text(
                  '© 2025 Registro de Compras. Todos os direitos reservados.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange[600],
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.orange[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}