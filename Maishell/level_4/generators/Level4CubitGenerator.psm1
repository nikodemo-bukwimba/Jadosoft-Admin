# ============================================================
# Level4CubitGenerator.psm1
# Generates:
#   presentation/cubit/{fname}_cubit.dart
#   presentation/cubit/{fname}_state.dart
# ============================================================

function Invoke-GenerateCubit {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    _Gen-State -Ctx $Ctx -NewFile $NewFile
    _Gen-Cubit -Ctx $Ctx -NewFile $NewFile
}

function _Gen-State {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:equatable/equatable.dart';
import '../../domain/projections/${fname}_projection.dart';

abstract class ${fclass}State extends Equatable {
  const ${fclass}State();
  @override
  List<Object?> get props => [];
}

class ${fclass}Initial extends ${fclass}State {}

class ${fclass}Loading extends ${fclass}State {}

class ${fclass}Loaded extends ${fclass}State {
  final ${fclass}Projection projection;
  const ${fclass}Loaded(this.projection);

  @override
  List<Object?> get props => [projection];
}

class ${fclass}Error extends ${fclass}State {
  final String message;
  const ${fclass}Error(this.message);

  @override
  List<Object?> get props => [message];
}
"@
    & $NewFile (Join-Path $fDir "presentation\cubit\${fname}_state.dart") $content
}

function _Gen-Cubit {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_${fname}_usecase.dart';
import '${fname}_state.dart';

class ${fclass}Cubit extends Cubit<${fclass}State> {
  final Get${fclass}UseCase _getProjection;

  ${fclass}Cubit({required Get${fclass}UseCase getProjection})
      : _getProjection = getProjection,
        super(${fclass}Initial());

  Future<void> load() async {
    emit(${fclass}Loading());
    final result = await _getProjection();
    result.fold(
      (failure) => emit(${fclass}Error(failure.toString())),
      (projection) => emit(${fclass}Loaded(projection)),
    );
  }

  Future<void> refresh() => load();
}
"@
    & $NewFile (Join-Path $fDir "presentation\cubit\${fname}_cubit.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateCubit'
