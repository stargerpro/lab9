import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(CheckoutApi()),
        child: const _BlocCartView(),
      );
}

class _BlocCartView extends StatefulWidget {
  const _BlocCartView();

  @override
  State<_BlocCartView> createState() => _BlocCartViewState();
}

class _BlocCartViewState extends State<_BlocCartView> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();

    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == CheckoutStatus.success) {
          messenger.hideCurrentMaterialBanner();
          messenger.showSnackBar(
            SnackBar(content: Text('Order placed: ${state.orderId}')),
          );
          _couponController.clear();
        } else if (state.status == CheckoutStatus.failure) {
          messenger.showMaterialBanner(
            MaterialBanner(
              content: Text(state.checkoutError ?? 'Checkout failed'),
              actions: [
                TextButton(
                  onPressed: messenger.hideCurrentMaterialBanner,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart · Bloc'),
          actions: [
            BlocSelector<CartBloc, CartState, double>(
              selector: (state) => state.total,
              builder: (context, total) {
                debugPrint('Bloc total rebuilt: $total');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(total.toStringAsFixed(2)),
                  ),
                );
              },
            ),
            BlocSelector<CartBloc, CartState, bool>(
              selector: (state) => state.canUndo,
              builder: (context, canUndo) => IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: canUndo ? () => bloc.add(const CartUndone()) : null,
              ),
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final submitting = state.status == CheckoutStatus.submitting;
            return Column(
              children: [
                Expanded(
                  child: CartBody(
                    lines: state.lines,
                    onAdd: (p) => bloc.add(CartProductAdded(p)),
                    onRemove: (id) => bloc.add(CartProductRemoved(id)),
                    onQtyChanged: (id, delta) =>
                        bloc.add(CartQtyChanged(id, delta)),
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
                          decoration: InputDecoration(
                            labelText: 'Coupon code',
                            errorText: state.couponError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => bloc
                            .add(CartCouponApplied(_couponController.text)),
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
                      onPressed: state.lines.isEmpty
                          ? null
                          : () => bloc.add(const CartCheckoutRequested()),
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
            );
          },
        ),
      ),
    );
  }
}