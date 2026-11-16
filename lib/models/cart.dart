import 'package:flutter/foundation.dart';

class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product.id == product.id && other.qty == qty;

  @override
  int get hashCode => Object.hash(product.id, qty);
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l,
    ];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  List<CartLine> changeQty(String id, int delta) {
    return [
      for (final l in this)
        if (l.product.id != id)
          l
        else if (l.qty + delta > 0)
          l.copyWith(qty: l.qty + delta),
    ];
  }

  double get subtotal => fold(0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const [],
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final List<CartState> history;

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == 'SAVE10' ? subtotal * 0.10 : 0.0;
  double get total => subtotal - discount;
  bool get canUndo => history.isNotEmpty;

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    bool clearCoupon = false,
    String? couponError,
    bool clearCouponError = false,
    CheckoutStatus? status,
    String? orderId,
    String? checkoutError,
    List<CartState>? history,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      checkoutError: checkoutError ?? this.checkoutError,
      history: history ?? this.history,
    );
  }

  CartState applyCoupon(String code) {
    final trimmed = code.trim();
    if (trimmed == 'SAVE10') {
      return copyWith(coupon: 'SAVE10', clearCouponError: true);
    }
    return copyWith(couponError: 'Invalid coupon');
  }

  @override
  bool operator ==(Object other) =>
      other is CartState &&
      listEquals(other.lines, lines) &&
      other.coupon == coupon &&
      other.couponError == couponError &&
      other.status == status &&
      other.orderId == orderId &&
      other.checkoutError == checkoutError &&
      listEquals(other.history, history);

  @override
  int get hashCode => Object.hash(Object.hashAll(lines), coupon, couponError,
      status, orderId, checkoutError, Object.hashAll(history));
}