import 'package:flutter/material.dart';
import 'package:smart_budget_app/dataBase_local/db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class Movimientos extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MovimientosState();
  }
}

class _MovimientosState extends State<Movimientos> {
  List<Map<String, dynamic>> movimientos = [];
  Database? _database;
  final Db _dbHelper = Db();

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  Future<void> _initDb() async {
    _database = await _dbHelper.open();
    await _deleteOldRecords();
    await _loadMovimientos();
  }

  Future<void> _deleteOldRecords() async {
    await _dbHelper.deleteRecordsWithNullBalanceId();
  }

  Future<void> _loadMovimientos() async {
    if (_database == null) return;

    final gastos = await _database!.rawQuery('''
      SELECT "Gasto" as tipo, cantidad, fecha, categoria, descripcion, id
      FROM gasto 
      WHERE fecha >= date('now', '-1 month') 
      ORDER BY fecha DESC
    ''');

    final ingresos = await _database!.rawQuery('''
      SELECT "Ingreso" as tipo, cantidad, fecha, categoria, descripcion, id
      FROM ingreso 
      WHERE fecha >= date('now', '-1 month') 
      ORDER BY fecha DESC
    ''');

    setState(() {
      movimientos = [...gastos, ...ingresos];
      movimientos.sort((a, b) => b['fecha'].compareTo(a['fecha']));
    });
  }

  List<String> _categorias_gasto = [
  "Alimentación", "Vivienda", "Transporte", "Salud", "Entretenimiento", 
  "Educación", "Servicios", "Otros"
];
  

String? _categoriaSeleccionadaGasto;

// Categorías para Ingresos
  List<String> _categorias_ingreso = [
    "Sueldo", "Freelance", "Ingresos pasivos", "Regalos", "Otros"
  ];

// Variable para guardar la categoría seleccionada
  String? _categoriaSeleccionadaIngreso;

// Función para formatear la fecha en "AAAA/MM/DD HH:mm"
String formatFecha(DateTime fecha) {
  final DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
  return formatter.format(fecha);
}
  Future<void> _addMovimiento(String type, String descripcion, double cantidad, String categoria) async {
  if (_database == null) return;

  String table = type.toLowerCase();

  // Obtener el mes y año actuales
  final now = DateTime.now();
  final month = now.month;
  final year = now.year;

  final balanceId = '${month.toString().padLeft(2, '0')}${year.toString().substring(2)}';
  final balance = await _database!.query('balance', where: 'id =?', whereArgs: [balanceId]);
  if (balance.isEmpty) {
    // Si no existe, crear un nuevo balance con el balanceId correspondiente
    final fechaInicio = DateTime(year, month, 1);
    await _database!.insert(
      'balance',
      {
        'id': balanceId,
        'nombre': 'Balance${month.toString().padLeft(2, '0')}',
        'fechaInicio': fechaInicio.toIso8601String(),
        'limiteGastos': 10000000,
        'porcentajeDeError': 3,
      },
    );
  }

  // Continuar con la creación del movimiento
  await _database!.insert(
    table,
    {
      'descripcion': descripcion,
      'cantidad': cantidad,
      'fecha': DateTime.now().toIso8601String(), 
      'categoria': categoria,
      'balanceId': '${month.toString().padLeft(2, '0')}${year.toString().substring(2)}',  
    },
  );

  await _loadMovimientos();
}

  Future<void> _editMovimiento(int id, String type, String descripcion, double cantidad, String categoria) async {
    if (_database == null) return;

    String table = type.toLowerCase();

    await _database!.update(
      table,
      {
        'descripcion': descripcion,
        'cantidad': cantidad,
        'categoria': categoria,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _loadMovimientos();
  }

  Future<void> _deleteMovimiento(int id, String type) async {
    if (_database == null) return;

    String table = type.toLowerCase();

    await _database!.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );

    await _loadMovimientos();
  }
Widget _buildMovimientoItem(Map<String, dynamic> movimiento) {
  final tipo = movimiento['tipo'];
  final descripcion = movimiento['descripcion'];
  final cantidad = movimiento['cantidad'];
  final id = movimiento['id'];
  final categoria = movimiento['categoria'];

  // Convertir la fecha si es una cadena
  DateTime fechaMovimiento;
  if (movimiento['fecha'] is String) {
    fechaMovimiento = DateTime.parse(movimiento['fecha']);
  } else {
    fechaMovimiento = movimiento['fecha'];
  }

  // Formatear la fecha usando formatFecha
  String fechaFormateada = formatFecha(fechaMovimiento);

  return Container(
    padding: const EdgeInsets.all(16.0),
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    decoration: BoxDecoration(
      color: Color(0xFF2A2C7F), // Color de fondo
      borderRadius: BorderRadius.circular(20),
    ),
    child: ListTile(
    title: Text(
      tipo,
      style: TextStyle(color: Colors.white),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Text(
          "Categoría: $categoria",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          "Descripción: $descripcion",
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 4),
        Text(
          "Fecha: $fechaFormateada", // Mostrar la fecha formateada
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${cantidad.toStringAsFixed(2)}',
              style: TextStyle(
                color: tipo == 'Gasto' ? Color(0xFFF2003D) : Color(0xFF27D0C6),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    openEditDialog(id, tipo, descripcion, cantidad, categoria);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF27D0C6), 
                    shape: CircleBorder(), 
                    minimumSize: Size(36, 36), 
                  ),
                  child: Icon(Icons.edit, color: Colors.white, size: 18), 
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _deleteMovimiento(id, tipo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2003D),
                    shape: CircleBorder(),
                    minimumSize: Size(36, 36),
                  ),
                  child: Icon(Icons.delete, color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  )
  );
}

  Widget _buildEmptyMessage() {
    return Center(
      child: Text(
        "No hay movimientos para mostrar",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF1A1C60),
        appBar: AppBar(
          title: Text(
            "Movimientos",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1C60),
        ),
        body: Center(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 15),
                  Expanded(
                    child: movimientos.isEmpty
                        ? _buildEmptyMessage()
                        : ListView.builder(
                            itemCount: movimientos.length,
                            itemBuilder: (context, index) {
                              final movimiento = movimientos[index];
                              return _buildMovimientoItem(movimiento);
                            },
                          ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      openOptionDialog(); 
                    },
                    child: Icon(
                      Icons.add,
                      color: Color(0xFFF2003D),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future openOptionDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Seleccionar Tipo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Ingreso"),
                onTap: () {
                  Navigator.of(context).pop();
                  openCreateDialog("Ingreso");
                },
              ),
              ListTile(
                title: Text("Gasto"),
                onTap: () {
                  Navigator.of(context).pop();
                  openCreateDialog("Gasto");
                },
              ),
              
            ],
          ),
        ),
      );

Future openCreateDialog(String type) => showDialog(
  context: context,
  builder: (context) {
    final _descripcionController = TextEditingController();
    final _cantidadController = TextEditingController();

    // Variable local para almacenar la categoría seleccionada
    String? _categoriaSeleccionada = type == "Ingreso" ? _categoriaSeleccionadaIngreso : _categoriaSeleccionadaGasto;

    // Lista de categorías según el tipo
    List<String> categorias = type == "Ingreso" ? _categorias_ingreso : _categorias_gasto;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text("Crear $type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),
              DropdownButton<String>(
                value: _categoriaSeleccionada,
                hint: Text("Seleccione una categoría"),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                    if (type == "Ingreso") {
                      _categoriaSeleccionadaIngreso = newValue;
                    } else {
                      _categoriaSeleccionadaGasto = newValue;
                    }
                  });
                },
                items: categorias.map<DropdownMenuItem<String>>((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Ingrese el valor del movimiento",
                ),
              ),
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  hintText: "Ingrese la descripción del movimiento",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final descripcion = _descripcionController.text;
                final cantidad = double.parse(_cantidadController.text);
                final categoria = _categoriaSeleccionada ?? "";
                _addMovimiento(type, descripcion, cantidad, categoria);
                Navigator.of(context).pop();
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  },
);
Future openEditDialog(int id, String type, String descripcion, double cantidad, String categoria) => showDialog(
  context: context,
  builder: (context) {
    final _descripcionController = TextEditingController(text: descripcion);
    final _cantidadController = TextEditingController(text: cantidad.toString());

    // Variable local para almacenar la categoría seleccionada
    String? _categoriaSeleccionada = categoria;

    // Lista de categorías según el tipo
    List<String> categorias = type == "Ingreso" ? _categorias_ingreso : _categorias_gasto;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text("Editar $type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _categoriaSeleccionada,
                hint: Text("Seleccione una categoría"),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                  });
                },
                items: categorias.map<DropdownMenuItem<String>>((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
              ),
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  hintText: "Ingrese la descripción del movimiento",
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Ingrese el valor del movimiento",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final descripcion = _descripcionController.text;
                final cantidad = double.parse(_cantidadController.text);
                final categoria = _categoriaSeleccionada ?? "";
                _editMovimiento(id, type, descripcion, cantidad, categoria);
                Navigator.of(context).pop();
              },
              child: Text("Guardar"),
            ),
          ],                
        );
      },
    );
  },
);

}