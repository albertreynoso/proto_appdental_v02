import 'package:flutter/material.dart';

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

/// [AnimationController]s can be created with `vsync: this` because of
/// [TickerProviderStateMixin].
class _TabBarExampleState extends State<TabBarExample>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tu TabBar personalizado
          TabBar(
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            padding: EdgeInsets.zero,
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Tratamientos'),
              Tab(text: 'Pagos'),
              Tab(text: 'Historial'),
              Tab(text: 'Documentos'),
              Tab(text: 'Notas'),
            ],
          ),
          // El contenido de los tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                Center(child: Text("It's cloudy here")),
                Center(child: Text("It's rainy here")),
                Center(child: Text("It's sunny here")),
                Center(child: Text("It's rainy here")),
                Center(child: Text("It's sunny here")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
