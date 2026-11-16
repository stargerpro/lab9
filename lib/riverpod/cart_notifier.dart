import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

final sharedPrefsProvider = Provider<SharedPreferences?>((ref) => null);

const _cartKey = 'riverpod_cart';

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[];
  Timer? _couponTimer;

  @override
  CartState build() {
    ref.onDispose(() => _couponTimer?.cancel());
    final prefs = ref.watch(sharedPrefsProvider);
    listenSelf((previous, next) {
      prefs?.setString(_cartKey, jsonEncode(next.toJson()));
    });
    final saved = prefs?.getString(_cartKey);
    if (saved == null) return const CartState();
    return CartState.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  }

  bool get canUndo => _history.isNotEmpty;

  void _save() => _history.add(state);

  void add(Product p) {
    _save();
    state = state.copyWith(lines: state.lines.withProduct(p));
  }

  void remove(String id) {
    _save();
    state = state.copyWith(lines: state.lines.without(id));
  }

  void changeQty(String id, int delta) {
    _save();
    state = state.copyWith(lines: state.lines.changeQty(id, delta));
  }

  void applyCoupon(String code) {
    _save();
    state = state.applyCoupon(code);
  }

  void couponTyped(String code) {
    _couponTimer?.cancel();
    _couponTimer = Timer(const Duration(milliseconds: 400), () {
      state = state.validateCoupon(code);
    });
  }

  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast();
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.status == CheckoutStatus.submitting) return;
    final api = ref.read(checkoutApiProvider);
    state = state.copyWith(status: CheckoutStatus.submitting);
    try {
      final orderId = await api.submit(state.total);
      _history.clear();
      state = CartState(status: CheckoutStatus.success, orderId: orderId);
    } on CheckoutException catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});