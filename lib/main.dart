import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'models/cart.dart';
import 'riverpod/cart_notifier.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(
      Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    final next = transition.nextState;
    if (next is CartState) {
      debugPrint('Bloc: ${transition.event.runtimeType} -> '
          '${next.itemCount} items, coupon ${next.coupon}');
    }
  }
}

final class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
      ProviderObserverContext context, Object? previousValue, Object? newValue) {
    if (newValue is CartState) {
      debugPrint('Riverpod: cart -> ${newValue.itemCount} items, '
          'coupon ${newValue.coupon}');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path),
  );
  Bloc.observer = const AppBlocObserver();
  runApp(ProviderScope(
    observers: [AppProviderObserver()],
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const CartApp(),
  ));
}

class CartApp extends StatelessWidget {
  const CartApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Cart four ways',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart: four ways')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _open(context, const SetStateCartPage()),
              child: const Text('setState'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(context, const RiverpodCartPage()),
              child: const Text('Riverpod'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(context, const CubitCartPage()),
              child: const Text('Cubit'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(context, const BlocCartPage()),
              child: const Text('Bloc'),
            ),
          ],
        ),
      ),
    );
  }
}