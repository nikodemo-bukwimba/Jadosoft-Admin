// profile_bloc.dart
import 'package:fca/core/usecase/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
import '../../domain/usecases/get_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfile;

  ProfileBloc(this._getProfile) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _getProfile(NoParams());
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }
}
