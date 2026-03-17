// report_export_service.dart
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
      return Right(await _client.requestExport(request));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Export request failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, GetExportStatusResponse>> getExportStatus(String exportId) async {
    try {
      return Right(await _client.getExportStatus(exportId));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Status check failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, DownloadExportResponse>> downloadExport(String exportId) async {
    try {
      return Right(await _client.downloadExport(exportId));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Download failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}