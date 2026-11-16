import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() => _RiverpodCartPageState();
}

class _RiverpodCartPageState extends ConsumerState<RiverpodCartPage> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final canUndo = ref.watch(canUndoProvider);

    ref.listen(cartProvider.select((s) => s.status), (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next == CheckoutStatus.success) {
        messenger.hideCurrentMaterialBanner();
        messenger.showSnackBar(
          SnackBar(content: Text('Order placed: ${ref.read(cartProvider).orderId}')),
        );
        _couponController.clear();
      } else if (next == CheckoutStatus.failure) {
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Text(ref.read(cartProvider).checkoutError ?? 'Checkout failed'),
            actions: [
              TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    });

    final submitting = state.status == CheckoutStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          const _TotalChip(),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: state.lines,
              onAdd: cart.add,
              onRemove: cart.remove,
              onQtyChanged: cart.changeQty,
              itemCount: state.itemCount,
              subtotal: state.subtotal,
              discount: state.discount,
              total: state.total,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    onChanged: cart.couponTyped,
                    decoration: InputDecoration(
                      labelText: 'Coupon code',
                      errorText: state.couponError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => cart.applyCoupon(_couponController.text),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting || state.lines.isEmpty ? null : cart.checkout,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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

class _TotalChip extends ConsumerWidget {
  const _TotalChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartProvider.select((s) => s.total));
    debugPrint('TotalChip rebuilt: $total');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(total.toStringAsFixed(2)),
      ),
    );
  }
}