import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key, this.api});

  final CheckoutApi? api;

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();
  final List<CartState> _history = []; // T5: Undo history
  final _couponController = TextEditingController();
  late final CheckoutApi _api = widget.api ?? CheckoutApi();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // Helper to push state to _history before mutating (T5)
  void _mutate(CartState Function(CartState current) transform) {
    setState(() {
      _history.add(_state);
      _state = transform(_state);
    });
  }

  void _add(Product p) =>
      _mutate((s) => s.copyWith(lines: s.lines.withProduct(p)));

  void _remove(String id) =>
      _mutate((s) => s.copyWith(lines: s.lines.without(id)));

  // T1: Quantity stepper
  void _changeQty(String id, int delta) =>
      _mutate((s) => s.copyWith(lines: s.lines.changeQty(id, delta)));

  // T2: Apply coupon
  void _applyCoupon() =>
      _mutate((s) => s.applyCoupon(_couponController.text));

  // T5: Undo action
  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _state = _history.removeLast();
    });
  }

  // T4: Async checkout
  Future<void> _checkout() async {
    setState(() {
      _state = _state.copyWith(status: CheckoutStatus.submitting);
    });

    try {
      final orderId = await _api.submit(_state.total);
      if (!mounted) return; // Guard against disposed widget

      _couponController.clear();
      setState(() {
        _history.clear();
        _state = CartState(
          status: CheckoutStatus.success,
          orderId: orderId,
        );
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showSnackBar(
          SnackBar(content: Text('Order placed: $orderId')),
        );
    } on CheckoutException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        );
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(
          MaterialBanner(
            content: Text('Checkout failed: ${e.message}'),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('DISMISS'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = _state.status == CheckoutStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          // T5: Undo button in AppBar
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _history.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: _state.lines,
              onAdd: _add,
              onRemove: _remove,
              onQtyChanged: _changeQty,
              itemCount: _state.itemCount,
              subtotal: _state.subtotal,
              discount: _state.discount,
              total: _state.total,
            ),
          ),
          // T2: Coupon input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      labelText: 'Coupon code',
                      errorText: _state.couponError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyCoupon,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          // T4: Checkout button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_state.lines.isEmpty || isSubmitting) ? null : _checkout,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}