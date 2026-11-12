import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    this.onQtyChanged,
    this.itemCount,
    this.subtotal,
    this.discount,
    this.total,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta)? onQtyChanged;

  // Optional summary values so earlier pages don't break before you update them
  final int? itemCount;
  final double? subtotal;
  final double? discount;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final displayCount = itemCount ?? lines.itemCount;
    final displaySubtotal = subtotal ?? lines.subtotal;
    final displayDiscount = discount ?? 0.0;
    final displayTotal = total ?? displaySubtotal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in catalog)
                ActionChip(
                  label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                  onPressed: () => onAdd(p),
                ),
            ],
          ),
        ),
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final l in lines)
                      ListTile(
                        key: ValueKey(l.product.id),
                        title: Text(l.product.name),
                        subtitle: Text(
                          '${l.product.price.toStringAsFixed(2)} each · ${l.subtotal.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: onQtyChanged != null
                                  ? () => onQtyChanged!(l.product.id, -1)
                                  : () => onRemove(l.product.id),
                            ),
                            Text('${l.qty}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: onQtyChanged != null
                                  ? () => onQtyChanged!(l.product.id, 1)
                                  : () => onAdd(l.product),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        // T3: Summary Card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SummaryRow('Items', '$displayCount'),
                _SummaryRow('Subtotal', displaySubtotal.toStringAsFixed(2)),
                if (displayDiscount > 0)
                  _SummaryRow(
                    'Discount (10%)',
                    '-${displayDiscount.toStringAsFixed(2)}',
                  ),
                const Divider(),
                _SummaryRow(
                  'Total',
                  displayTotal.toStringAsFixed(2),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}