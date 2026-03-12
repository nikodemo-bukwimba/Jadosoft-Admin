import 'package:equatable/equatable.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../payment/domain/entities/payment_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

class SalesDashboardProjection extends Equatable {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final int confirmedPayments;
  final List<OrderEntity> recentOrders;
  final int productCount;
  final int featuredProductCount;
  final DateTime generatedAt;

  const SalesDashboardProjection({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.confirmedPayments,
    required this.recentOrders,
    required this.productCount,
    required this.featuredProductCount,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [totalOrders, totalRevenue, averageOrderValue, ordersByStatus, confirmedPayments, recentOrders, productCount, featuredProductCount, generatedAt];
}
