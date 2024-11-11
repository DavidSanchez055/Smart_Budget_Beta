import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_budget_app/dataBase_local/db.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyHomepage();
  }
}

class _MyHomepage extends State<MyHomePage> {
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

    final myPieChartSections = [
      PieChartSectionData(
        value: ingresosPorcentaje.toDouble(),
        color: Color(0xFF27D0C6),
        showTitle: false,
      ),
      PieChartSectionData(
        value: gastosPorcentaje.toDouble(),
        color: Color(0xFFF2003D),
        showTitle: false,
      ),
    ];

    final myBarGroups = [
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(
          toY: ingresosPorcentaje.toDouble(),
          color: Color(0xFF27D0C6),
          width: 10,
        ),
        BarChartRodData(
          toY: gastosPorcentaje.toDouble(),
          color: Color(0xFFF2003D),
          width: 10,
        ),
      ])
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF1A1C60),
        appBar: AppBar(
          title: Text(
            "Smart Budget",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1C60),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Título "Así está tu plata"
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2C7F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Así está tu plata",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Muestra el total, ingresos y gastos
                            Text(
                              "Total: \$${total.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Ingresos: \$${totalIngresos.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Gastos: \$${totalGastos.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Gráficos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // PieChart
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2C7F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: PieChart(
                              PieChartData(
                                sections: myPieChartSections,
                                centerSpaceRadius: 30,
                                sectionsSpace: 5,
                                startDegreeOffset: 90,
                              ),                             
                            ),
                          ),
                          // BarChart
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2C7F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: BarChart(
                              BarChartData(
                                barGroups: myBarGroups,
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Leyendas debajo de los gráficos
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
