import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

void main() => runApp(const ProviderScope(child: CartApp()));

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
