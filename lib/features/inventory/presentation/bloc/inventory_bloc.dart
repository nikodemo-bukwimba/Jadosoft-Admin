// lib/features/inventory/presentation/bloc/inventory_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_warehouse_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/get_variant_stock_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/usecases/receive_stock_usecase.dart';

import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetWarehousesUseCase getWarehousesUseCase;
  final CreateWarehouseUseCase createWarehouseUseCase;
  final GetBatchesUseCase getBatchesUseCase;
  final ReceiveStockUseCase receiveStockUseCase;
  final GetVariantStockUseCase getVariantStockUseCase;

  InventoryBloc({
    required this.getWarehousesUseCase,
    required this.createWarehouseUseCase,
    required this.getBatchesUseCase,
    required this.receiveStockUseCase,
    required this.getVariantStockUseCase,
  }) : super(InventoryLoaded()) {
    on<InventoryWarehousesLoadRequested>(_onLoadWarehouses);
    on<InventoryWarehouseCreateRequested>(_onCreateWarehouse);
    on<InventoryBatchesLoadRequested>(_onLoadBatches);
    on<InventoryReceiveStockRequested>(_onReceiveStock);
    on<InventoryVariantStockLoadRequested>(_onLoadVariantStock);

    on<InventoryFormReset>((event, emit) {
      emit(InventoryLoaded());
    });
  }

  InventoryLoaded get currentState {
    if (state is InventoryLoaded) {
      return state as InventoryLoaded;
    }
    return InventoryLoaded();
  }

  Future<void> _onLoadWarehouses(
    InventoryWarehousesLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(currentState.copyWith(loading: true));

    final result = await getWarehousesUseCase(
      GetWarehousesParams(orgId: event.orgId),
    );

    result.fold(
      (f) {
        emit(currentState.copyWith(loading: false, errorMessage: f.message));
      },
      (warehouses) {
        emit(currentState.copyWith(loading: false, warehouses: warehouses));
      },
    );
  }

  Future<void> _onCreateWarehouse(
    InventoryWarehouseCreateRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(currentState.copyWith(loading: true));

    final result = await createWarehouseUseCase(
      CreateWarehouseParams(
        orgId: event.orgId,
        name: event.name,
        type: event.type,
      ),
    );

    result.fold(
      (f) {
        emit(currentState.copyWith(loading: false, errorMessage: f.message));
      },
      (warehouse) {
        final updatedWarehouses = [...currentState.warehouses, warehouse];

        emit(
          currentState.copyWith(
            loading: false,
            warehouses: updatedWarehouses,
            createdWarehouse: warehouse,
            successMessage: 'Warehouse created successfully',
          ),
        );
      },
    );
  }

  Future<void> _onLoadBatches(
    InventoryBatchesLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(currentState.copyWith(loading: true));

    final result = await getBatchesUseCase(
      GetBatchesParams(
        orgId: event.orgId,
        warehouseId: event.warehouseId,
        productId: event.productId,
        variantId: event.variantId,
        status: event.status,
      ),
    );

    result.fold(
      (f) {
        emit(currentState.copyWith(loading: false, errorMessage: f.message));
      },
      (batches) {
        emit(currentState.copyWith(loading: false, batches: batches));
      },
    );
  }

  Future<void> _onReceiveStock(
    InventoryReceiveStockRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(currentState.copyWith(loading: true));

    final result = await receiveStockUseCase(
      ReceiveStockParams(
        warehouseId: event.warehouseId,
        productId: event.productId,
        variantId: event.variantId,
        orgId: event.orgId,
        quantity: event.quantity,
        unitCost: event.unitCost,
        currency: event.currency,
        batchNumber: event.batchNumber,
        sku: event.sku,
        expiresAt: event.expiresAt,
        bestBeforeAt: event.bestBeforeAt,
      ),
    );

    result.fold(
      (f) {
        emit(currentState.copyWith(loading: false, errorMessage: f.message));
      },
      (batch) {
        final updatedBatches = [batch, ...currentState.batches];

        emit(
          currentState.copyWith(
            loading: false,
            batches: updatedBatches,
            receivedBatch: batch,
            successMessage: 'Stock received successfully',
          ),
        );
      },
    );
  }

  Future<void> _onLoadVariantStock(
    InventoryVariantStockLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(currentState.copyWith(loading: true));

    final result = await getVariantStockUseCase(
      GetVariantStockParams(orgId: event.orgId, variantId: event.variantId),
    );

    result.fold(
      (f) {
        emit(currentState.copyWith(loading: false, errorMessage: f.message));
      },
      (stock) {
        emit(currentState.copyWith(loading: false, variantStock: stock));
      },
    );
  }
}
