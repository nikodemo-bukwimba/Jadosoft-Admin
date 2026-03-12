import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/client/report_export_client.dart';
import '../models/request_export_response.dart';
import '../models/request_export_request.dart';
import '../models/get_export_status_response.dart';
import '../models/download_export_response.dart';

class ReportExportService {
  final ReportExportClient _client;

  ReportExportService({required ReportExportClient client}) : _client = client;

  Future<Either<Failure, RequestExportResponse>> requestExport(RequestExportRequest request) async {
    try {
      final result = await _client.requestExport(request);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  Future<Either<Failure, GetExportStatusResponse>> getExportStatus(String exportId) async {
    try {
      final result = await _client.getExportStatus(exportId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  Future<Either<Failure, DownloadExportResponse>> downloadExport(String exportId) async {
    try {
      final result = await _client.downloadExport(exportId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
