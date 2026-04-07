import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../projections/sales_dashboard_projection.dart';
import '../providers/order_data_provider.dart';
import '../providers/payment_data_provider.dart';
import '../providers/product_data_provider.dart';

class GetSalesDashboardUseCase {
  final OrderDataProvider _orderProvider;
  final PaymentDataProvider _paymentProvider;
  final ProductDataProvider _productProvider;

  GetSalesDashboardUseCase({
    required OrderDataProvider orderProvider,
    required PaymentDataProvider paymentProvider,
    required ProductDataProvider productProvider,
  }) : _orderProvider = orderProvider,
       _paymentProvider = paymentProvider,
       _productProvider = productProvider;

  Future<Either<Failure, SalesDashboardProjection>> call() async {
    final orderResult = await _orderProvider.getAll();
    if (orderResult.isLeft()) {
      return orderResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final orderList = orderResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    final paymentResult = await _paymentProvider.getAll();
    if (paymentResult.isLeft()) {
      return paymentResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final paymentList = paymentResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    final productResult = await _productProvider.getAll();
    if (productResult.isLeft()) {
      return productResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final productList = productResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    // Orders
    final totalOrders = orderList.length;
    final totalRevenue = orderList.fold<double>(0.0, (s, e) => s + e.total);
    final averageOrderValue = orderList.isEmpty
        ? 0.0
        : totalRevenue / orderList.length;

    final ordersByStatus = <String, int>{};
    for (final e in orderList) {
      ordersByStatus[e.status] = (ordersByStatus[e.status] ?? 0) + 1;
    }

    // Payments — real counts from PaymentEntity.provider
    final confirmedPayments = paymentList.length;
    final paymentsByProvider = <String, int>{};
    for (final p in paymentList) {
      final key = p.provider.toLowerCase();
      paymentsByProvider[key] = (paymentsByProvider[key] ?? 0) + 1;
    }

    // Recent orders
    final sortedRecentOrders = List.of(orderList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentOrders = sortedRecentOrders.take(5).toList();

    // Products
    final productCount = productList.length;
    final featuredProductCount = productList
        .where((p) => p.isFeatured == true || p.isFeatured == 'true')
        .length;

    return Right(
      SalesDashboardProjection(
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        averageOrderValue: averageOrderValue,
        ordersByStatus: ordersByStatus,
        confirmedPayments: confirmedPayments,
        paymentsByProvider: paymentsByProvider,
        recentOrders: recentOrders,
        productCount: productCount,
        featuredProductCount: featuredProductCount,
        generatedAt: DateTime.now(),
      ),
    );
  }
}
