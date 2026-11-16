import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../models/cart.dart';
import 'cart_bloc.dart';

class PersistedCartBloc extends CartBloc with HydratedMixin<CartState> {
  PersistedCartBloc(super.api) {
    hydrate();
  }

  @override
  CartState? fromJson(Map<String, dynamic> json) => CartState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(CartState state) => state.toJson();
}