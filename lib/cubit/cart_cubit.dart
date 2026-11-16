import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    debugPrint('CartCubit onChange: ${change.currentState.itemCount} items '
        '-> ${change.nextState.itemCount} items, coupon ${change.nextState.coupon}');
  }

  void _update(CartState next) {
    if (next == state) {
      emit(next);
      return;
    }
    emit(next.copyWith(
      history: [...state.history, state.copyWith(history: const [])],
    ));
  }

  void add(Product p) =>
      _update(state.copyWith(lines: state.lines.withProduct(p)));

  void remove(String id) =>
      _update(state.copyWith(lines: state.lines.without(id)));

  void changeQty(String id, int delta) =>
      _update(state.copyWith(lines: state.lines.changeQty(id, delta)));

  void applyCoupon(String code) => _update(state.applyCoupon(code));

  void undo() {
    if (!state.canUndo) return;
    final previous = state.history.last;
    emit(previous.copyWith(
      history: state.history.sublist(0, state.history.length - 1),
    ));
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.status == CheckoutStatus.submitting) return;
    emit(state.copyWith(status: CheckoutStatus.submitting));
    try {
      final orderId = await _api.submit(state.total);
      if (isClosed) return;
      emit(CartState(status: CheckoutStatus.success, orderId: orderId));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      ));
    }
  }
}