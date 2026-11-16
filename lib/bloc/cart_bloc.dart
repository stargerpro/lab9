import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

EventTransformer<E> debounceTransformer<E>(Duration duration) =>
    (events, mapper) => events.debounce(duration).switchMap(mapper);

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>((event, emit) => _apply(
        event, emit, state.copyWith(lines: state.lines.withProduct(event.product))));
    on<CartProductRemoved>((event, emit) => _apply(
        event, emit, state.copyWith(lines: state.lines.without(event.productId))));
    on<CartQtyChanged>((event, emit) => _apply(event, emit,
        state.copyWith(lines: state.lines.changeQty(event.productId, event.delta))));
    on<CartCouponApplied>(
        (event, emit) => _apply(event, emit, state.applyCoupon(event.code)));
    on<CartCouponTyped>(
      (event, emit) => _apply(event, emit, state.validateCoupon(event.code)),
      transformer: debounceTransformer(const Duration(milliseconds: 400)),
    );
    on<CartUndone>(_onUndone);
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
  }

  final CheckoutApi _api;

  bool _isUndoable(CartEvent event) => switch (event) {
        CartProductAdded() ||
        CartProductRemoved() ||
        CartQtyChanged() ||
        CartCouponApplied() =>
          true,
        CartCouponTyped() || CartCheckoutRequested() || CartUndone() => false,
      };

  void _apply(CartEvent event, Emitter<CartState> emit, CartState next) {
    if (next == state) return;
    if (_isUndoable(event)) {
      emit(next.copyWith(
        history: [...state.history, state.copyWith(history: const [])],
      ));
    } else {
      emit(next);
    }
  }

  void _onUndone(CartUndone event, Emitter<CartState> emit) {
    if (!state.canUndo) return;
    final previous = state.history.last;
    emit(previous.copyWith(
      history: state.history.sublist(0, state.history.length - 1),
    ));
  }

  Future<void> _onCheckout(
      CartCheckoutRequested event, Emitter<CartState> emit) async {
    if (state.lines.isEmpty) return;
    emit(state.copyWith(status: CheckoutStatus.submitting));
    try {
      final orderId = await _api.submit(state.total);
      if (emit.isDone) return;
      emit(CartState(status: CheckoutStatus.success, orderId: orderId));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      ));
    }
  }
}