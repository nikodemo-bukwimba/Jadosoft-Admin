import 'package:equatable/equatable.dart';
import '../../../order/domain/entities/order_entity.dart';

class SalesDashboardProjection extends Equatable {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final int confirmedPayments;
  final Map<String, int> paymentsByProvider;
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
    required this.paymentsByProvider,
    required this.recentOrders,
    required this.productCount,
    required this.featuredProductCount,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    totalOrders,
    totalRevenue,
    averageOrderValue,
    ordersByStatus,
    confirmedPayments,
    paymentsByProvider,
    recentOrders,
    productCount,
    featuredProductCount,
    generatedAt,
  ];
}
