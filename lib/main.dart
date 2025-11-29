import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/database_lib.dart';
import 'services/ble_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MetabolicHealthApp()));
  // make db
  var db = await DBUtils.db;
  //DBUtils.deleteDB();
  //DBUtils.printDBs();
  DBUtils.printDBEntries(db, desc: false);
  // run services
  BleService().startScan();
}

class MetabolicHealthApp extends StatelessWidget {
  const MetabolicHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return MaterialApp.router(
      title: 'Metabolic Health Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter.config(),
      debugShowCheckedModeBanner: false,
    );
  }
}
