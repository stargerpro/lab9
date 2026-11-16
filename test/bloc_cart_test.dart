import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  final keyboard = catalog.first;
  late MockCheckoutApi api;

  setUp(() => api = MockCheckoutApi());

  blocTest<CartBloc, CartState>(
    'two keyboards and SAVE10 emit three states ending at 88.2',
    build: () => CartBloc(api),
    act: (bloc) => bloc
      ..add(CartProductAdded(keyboard))
      ..add(CartProductAdded(keyboard))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [
      isA<CartState>().having((s) => s.subtotal, 'subtotal', 49),
      isA<CartState>().having((s) => s.subtotal, 'subtotal', 98),
      isA<CartState>()
          .having((s) => s.coupon, 'coupon', 'SAVE10')
          .having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting then failure and keeps the lines',
    setUp: () => when(() => api.submit(any())).thenAnswer(
        (_) => Future.error(const CheckoutException('Card declined'))),
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (bloc) => bloc.add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable: checkout twice submits only once',
    setUp: () =>
        when(() => api.submit(any())).thenAnswer((_) async => 'ORD-1'),
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (bloc) => bloc
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.success),
    ],
    verify: (_) => verify(() => api.submit(any())).called(1),
  );
}