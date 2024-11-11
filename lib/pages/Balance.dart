import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_budget_app/dataBase_local/db.dart';

class Balance extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BalanceState();
  }
}

class _BalanceState extends State<Balance> {
  double totalIngresos = 0;
  double totalGastos = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final db = Db();
    final ingresos = await db.obtenerTotalIngresos();
    final gastos = await db.obtenerTotalGastos();

    setState(() {
      totalIngresos = ingresos;
      totalGastos = gastos;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = totalIngresos - totalGastos;
    final ingresosPorcentaje = total == 0 ? 0 : (totalIngresos / total) * 100;
    final gastosPorcentaje = total == 0 ? 0 : (totalGastos / total) * 100;

    final myPieSections = [
      PieChartSectionData(
        value: ingresosPorcentaje.toDouble(),
        color: Color(0xFF27D0C6),
        title: "Ingresos",
        showTitle: false,
        titleStyle: TextStyle(color: Colors.white, fontSize: 20),
        borderSide: BorderSide(width: 2.0, color: Colors.white),
        radius: 100,
      ),
      PieChartSectionData(
        value: gastosPorcentaje.toDouble(),
        color: Color(0xFFF2003D),
        title: "Gastos",
        showTitle: false,
        titleStyle: TextStyle(color: Colors.white, fontSize: 20),
        borderSide: BorderSide(width: 2.0, color: Colors.white),
        radius: 100,
      ),
    ];

    final myBarGroups = [
  BarChartGroupData(x: 1, barRods: [
    BarChartRodData(
      toY: ingresosPorcentaje.toDouble(), // Cambiado de `y` a `toY`
      color: Color(0xFF27D0C6),
      width: 20,
    ),
    BarChartRodData(
      toY: gastosPorcentaje.toDouble(), // Cambiado de `y` a `toY`
      color:Color(0xFFF2003D),
      width: 20,
    ),
  ])
];


    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF1A1C60),
        appBar: AppBar(
          title: Text(
            "Balance",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1C60),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Porcentaje de Balances",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Contenedor con el PieChart
                    Container(
                      height: 350,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2C7F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: myPieSections,
                                centerSpaceRadius: 0,
                                sectionsSpace: 10,
                                startDegreeOffset: 90,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: Color(0xFF27D0C6),
                                text: "Ingresos",
                              ),
                              SizedBox(width: 20),
                              _buildLegendItem(
                                color: Color(0xFFF2003D),
                                text: "Gastos",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Contenedor con el BarChart
                    Container(
                      height: 350,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2C7F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                barGroups: myBarGroups,
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(show: false),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: Color(0xFF27D0C6),
                                text: "Ingresos",
                              ),
                              SizedBox(width: 20),
                              _buildLegendItem(
                                color: Color(0xFFF2003D),
                                text: "Gastos",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
