import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  final keyboard = catalog.first;
  late MockCheckoutApi api;

  setUp(() => api = MockCheckoutApi());

  blocTest<CartCubit, CartState>(
    'two keyboards and SAVE10 emit three states ending at 88.2',
    build: () => CartCubit(api),
    act: (cubit) {
      cubit.add(keyboard);
      cubit.add(keyboard);
      cubit.applyCoupon('SAVE10');
    },
    expect: () => [
      isA<CartState>().having((s) => s.subtotal, 'subtotal', 49),
      isA<CartState>().having((s) => s.subtotal, 'subtotal', 98),
      isA<CartState>()
          .having((s) => s.coupon, 'coupon', 'SAVE10')
          .having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting then failure and keeps the lines',
    setUp: () => when(() => api.submit(any())).thenAnswer(
        (_) => Future.error(const CheckoutException('Card declined'))),
    build: () => CartCubit(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (cubit) => cubit.checkout(),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );
}