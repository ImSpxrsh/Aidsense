import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_error_model.dart';

enum DataSource {
  noContent,
  badRequest,
  forbidden,
  unauthorized,
  notFound,
  internalServerError,
  connectionTimeout,
  cancel,
  receiveTimeout,
  sendTimeout,
  cacheError,
  noInternetConnection,
  defaultError,
}

class ResponseCode {
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int apiLogicError = 422;
  static const int internalServerError = 500;
  // MARK: - Local Error Codes.
  static const int connectionTimeout = -1;
  static const int cancel = -2;
  static const int receiveTimeout = -3;
  static const int sendTimeout = -4;
  static const int cacheError = -5;
  static const int noInternetConnection = -6;
  static const int defaultError = -7;
}

class ResponseMessage {
  static const String success = ApiErrors.success;
}

extension DataSourceExtension on DataSource {
  ApiErrorModel getFailure() {
    switch (this) {
      case DataSource.noContent:
        return const ApiErrorModel(
          message: ApiErrors.noContent,
          code: ResponseCode.noContent,
        );
      case DataSource.badRequest:
        return const ApiErrorModel(
          message: ApiErrors.badRequest,
          code: ResponseCode.badRequest,
        );
      case DataSource.forbidden:
        return const ApiErrorModel(
          message: ApiErrors.forbidden,
          code: ResponseCode.forbidden,
        );
      case DataSource.unauthorized:
        return const ApiErrorModel(
          message: ApiErrors.unauthorized,
          code: ResponseCode.unauthorized,
        );
      case DataSource.notFound:
        return const ApiErrorModel(
          message: ApiErrors.notFound,
          code: ResponseCode.notFound,
        );
      case DataSource.internalServerError:
        return const ApiErrorModel(
          message: ApiErrors.internalServerError,
          code: ResponseCode.internalServerError,
        );
      case DataSource.connectionTimeout:
        return const ApiErrorModel(
          message: ApiErrors.connectionTimeout,
          code: ResponseCode.connectionTimeout,
        );
      case DataSource.cancel:
        return const ApiErrorModel(
          message: ApiErrors.cancel,
          code: ResponseCode.cancel,
        );
      case DataSource.receiveTimeout:
        return const ApiErrorModel(
          message: ApiErrors.receiveTimeout,
          code: ResponseCode.receiveTimeout,
        );
      case DataSource.sendTimeout:
        return const ApiErrorModel(
          message: ApiErrors.sendTimeout,
          code: ResponseCode.sendTimeout,
        );
      case DataSource.cacheError:
        return const ApiErrorModel(
          message: ApiErrors.cacheError,
          code: ResponseCode.cacheError,
        );
      case DataSource.noInternetConnection:
        return const ApiErrorModel(
          message: ApiErrors.noInternetConnection,
          code: ResponseCode.noInternetConnection,
        );
      default:
        return const ApiErrorModel(
          message: ApiErrors.defaultError,
          code: ResponseCode.defaultError,
        );
    }
  }
}

class ErrorHandler implements Exception {
  late ApiErrorModel apiErrorModel;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      apiErrorModel = _handleError(error);
    } else {
      apiErrorModel = DataSource.defaultError.getFailure();
    }
  }
}

ApiErrorModel _handleError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return DataSource.connectionTimeout.getFailure();
    case DioExceptionType.sendTimeout:
      return DataSource.sendTimeout.getFailure();
    case DioExceptionType.receiveTimeout:
      return DataSource.receiveTimeout.getFailure();
    case DioExceptionType.badResponse:
      if (error.response != null &&
          error.response?.statusMessage != null &&
          error.response?.statusMessage != null) {
        return ApiErrorModel.fromJson(error.response?.data);
      } else {
        return DataSource.defaultError.getFailure();
      }
    case DioExceptionType.cancel:
      return DataSource.cancel.getFailure();
    default:
      return DataSource.defaultError.getFailure();
  }
}

class ApiInternalStatus {
  static const int success = 1;
  static const int failure = 0;
}
