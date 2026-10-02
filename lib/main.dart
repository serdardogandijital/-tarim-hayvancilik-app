import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/location_notifier.dart';
import 'screens/home_screen.dart';
import 'services/safe_list_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const TarimHayvancilikApp());
}

class TarimHayvancilikApp extends StatelessWidget {
  const TarimHayvancilikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationNotifier(),
      child: MaterialApp(
        title: 'Çiftçi+',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          fontFamily: 'Poppins',
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            titleTextStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        builder: (context, child) => ValueListenableBuilder<Set<String>>(
          valueListenable: SafeListStore.errors,
          builder: (context, errors, _) => Column(
            children: [
              if (errors.isNotEmpty)
                Material(
                  color: Colors.amber.shade100,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Bazı kayıtlar okunamadı veya kaydedilemedi. Mevcut veriler korunuyor; lütfen uygulamayı silmeyin.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              Expanded(child: child!),
            ],
          ),
        ),
        home: const HomeScreen(initialIndex: 1),
      ),
    );
  }
}
