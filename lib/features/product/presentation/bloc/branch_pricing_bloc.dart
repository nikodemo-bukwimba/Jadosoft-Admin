// lib/features/product/presentation/bloc/branch_pricing_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/branch_variant_price_entity.dart';
import '../../domain/repositories/branch_pricing_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class BranchPricingEvent extends Equatable {
  const BranchPricingEvent();
  @override
  List<Object?> get props => [];
}

class BranchPricingLoadRequested extends BranchPricingEvent {
  final String orgId;
  const BranchPricingLoadRequested(this.orgId);
  @override
  List<Object?> get props => [orgId];
}

class BranchPricingSetRequested extends BranchPricingEvent {
  final String orgId;
  final String variantId;
  final double price;
  final String currency;

  const BranchPricingSetRequested({
    required this.orgId,
    required this.variantId,
    required this.price,
    this.currency = 'TZS',
  });

  @override
  List<Object?> get props => [orgId, variantId, price, currency];
}

class BranchPricingRemoveRequested extends BranchPricingEvent {
  final String orgId;
  final String variantId;

  const BranchPricingRemoveRequested({
    required this.orgId,
    required this.variantId,
  });

  @override
  List<Object?> get props => [orgId, variantId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class BranchPricingState extends Equatable {
  const BranchPricingState();
  @override
  List<Object?> get props => [];
}

class BranchPricingInitial extends BranchPricingState {}

class BranchPricingLoading extends BranchPricingState {}

class BranchPricingLoaded extends BranchPricingState {
  final List<BranchVariantPriceEntity> overrides;
  const BranchPricingLoaded(this.overrides);
  @override
  List<Object?> get props => [overrides];
}

class BranchPricingOperationSuccess extends BranchPricingState {
  final String message;
  final List<BranchVariantPriceEntity>? updatedOverrides;

  const BranchPricingOperationSuccess(
    this.message, {
    this.updatedOverrides,
  });

  @override
  List<Object?> get props => [message, updatedOverrides];
}

class BranchPricingFailure extends BranchPricingState {
  final String message;
  const BranchPricingFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class BranchPricingBloc extends Bloc<BranchPricingEvent, BranchPricingState> {
  final BranchPricingRepository _repo;

  BranchPricingBloc({required BranchPricingRepository repository})
      : _repo = repository,
        super(BranchPricingInitial()) {
    on<BranchPricingLoadRequested>(_onLoad);
    on<BranchPricingSetRequested>(_onSet);
    on<BranchPricingRemoveRequested>(_onRemove);
  }

  Future<void> _onLoad(
    BranchPricingLoadRequested event,
    Emitter<BranchPricingState> emit,
  ) async {
    emit(BranchPricingLoading());
    final result = await _repo.listOverrides(event.orgId);
    result.fold(
      (f) => emit(BranchPricingFailure(f.message)),
      (overrides) => emit(BranchPricingLoaded(overrides)),
    );
  }

  Future<void> _onSet(
    BranchPricingSetRequested event,
    Emitter<BranchPricingState> emit,
  ) async {
    emit(BranchPricingLoading());
    final result = await _repo.setOverride(
      orgId: event.orgId,
      variantId: event.variantId,
      price: event.price,
      currency: event.currency,
    );
    await result.fold(
      (f) async => emit(BranchPricingFailure(f.message)),
      (_) async {
        // Reload the full list so the UI reflects the change
        final listResult = await _repo.listOverrides(event.orgId);
        listResult.fold(
          (f) => emit(
            BranchPricingOperationSuccess('Branch price saved.'),
          ),
          (overrides) => emit(
            BranchPricingOperationSuccess(
              'Branch price saved.',
              updatedOverrides: overrides,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRemove(
    BranchPricingRemoveRequested event,
    Emitter<BranchPricingState> emit,
  ) async {
    emit(BranchPricingLoading());
    final result = await _repo.removeOverride(
      orgId: event.orgId,
      variantId: event.variantId,
    );
    await result.fold(
      (f) async => emit(BranchPricingFailure(f.message)),
      (_) async {
        final listResult = await _repo.listOverrides(event.orgId);
        listResult.fold(
          (f) => emit(
            BranchPricingOperationSuccess('Branch price removed.'),
          ),
          (overrides) => emit(
            BranchPricingOperationSuccess(
              'Branch price removed. Reverted to root base price.',
              updatedOverrides: overrides,
            ),
          ),
        );
      },
    );
  }
}