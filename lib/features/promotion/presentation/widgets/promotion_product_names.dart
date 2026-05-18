import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../product/data/datasources/product_remote_datasource.dart';

class PromotionProductNames extends StatefulWidget {
  final List<String> productIds;
  final int maxItems;
  final TextStyle? style;

  const PromotionProductNames({
    super.key,
    required this.productIds,
    this.maxItems = 2,
    this.style,
  });

  @override
  State<PromotionProductNames> createState() => _PromotionProductNamesState();
}

class _PromotionProductNamesState extends State<PromotionProductNames> {
  bool loading = true;
  List<String> names = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = GetIt.instance<ProductRemoteDataSource>();

      final products = await Future.wait(
        widget.productIds.map((id) => ds.getById(id)),
      );

      if (!mounted) return;

      setState(() {
        names = products.map((e) => e.name).toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        names = widget.productIds;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text('Loading...', style: widget.style);
    }

    final visible = names.take(widget.maxItems).toList();

    var text = visible.join('  •  ');

    if (names.length > widget.maxItems) {
      text += ' +${names.length - widget.maxItems}';
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
