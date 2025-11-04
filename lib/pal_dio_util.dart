library pal_dio_util;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;

enum ApiMethods {
  get,
  post,
  put,
  delete,
}

class BaseRequest {
  BaseRequest();

  Map<String, dynamic> toJson() {
    return {};
  }

  factory BaseRequest.fromJson(Map<String, dynamic> json) {
    return BaseRequest();
  }
}

// Like a json annotation class
class DummyErrorResponse {
  DummyErrorResponse();

  // declare some custom fields

  factory DummyErrorResponse.fromJson(Map<String, dynamic> json) {
    return DummyErrorResponse();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

class PalResponse<T> {
  int statusCode;
  dynamic data;
  Map<String, dynamic>? json;
  String? error;
  T? apiData;

  PalResponse({required this.statusCode, this.data, this.error, this.json, this.apiData});

  bool get ok {
    return statusCode >= 200 && statusCode < 300;
  }

  @override
  String toString() {
    return "[PalResponse]: $statusCode, data: $data, error: $error, json: $json, apiData: $apiData";
  }
}

class PalDioUtil {
  PalDioUtil();

  // General Dio instance
  final _dio = Dio();

  // Default interceptors
  final List<InterceptorsWrapper> _defaultInterceptors = [
    InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
      return handler.resolve(error.response!);
    })
  ];

  void handleException(Map<String, dynamic> exceptionRespData) {}

  // Sub class can add their own interceptors here
  @protected
  List<InterceptorsWrapper> get userInterceptors {
    return [];
  }

  // Last dio instance interceptors hook, can be used to cover default interceptors.
  @protected
  List<InterceptorsWrapper> get interceptors {
    return _defaultInterceptors + userInterceptors;
  }

  // Last dio instance getter
  Dio get dioInstance {
    _dio.interceptors.addAll(interceptors);
    return _dio;
  }

  // Headers maker hook
  @protected
  Future<Map<String, dynamic>?> makeHeaders({authRequired = true}) async {
    return {};
  }

  // Dynamic api host hook
  @protected
  Future<String> getApiHost() async {
    return "";
  }

  // Options maker hook
  Future<Options> makeOptions({authRequired = true}) async {
    return Options(headers: await makeHeaders(authRequired: authRequired));
  }

  // General api call
  Future<PalResponse<RESP>> callApi<REQ extends BaseRequest, RESP>(
      ApiMethods method, String path,
      {REQ? dataReq,
      REQ? queriesReq,
      CancelToken? cancelToken,
      bool authRequired = true,
      void Function(int, int)? onReceiveProgress,
      void Function(int, int)? onSendProgress}) async {
    Options options = await makeOptions(authRequired: authRequired);
    var apiHost = await getApiHost();
    String url = "$apiHost$path";
    Response resp;

    PalResponse<RESP> palResp;
    try {
      switch (method) {
        case ApiMethods.get:
          resp = await dioInstance.get(url,
              data: dataReq?.toJson(),
              queryParameters: queriesReq?.toJson(),
              options: options,
              cancelToken: cancelToken,
              onReceiveProgress: onReceiveProgress);
          break;
        case ApiMethods.post:
          resp = await dioInstance.post(url,
              data: dataReq?.toJson(),
              queryParameters: queriesReq?.toJson(),
              options: options,
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
              onReceiveProgress: onReceiveProgress);
          break;
        case ApiMethods.put:
          resp = await dioInstance.put(url,
              data: dataReq?.toJson(),
              queryParameters: queriesReq?.toJson(),
              options: options,
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
              onReceiveProgress: onReceiveProgress);
          break;
        case ApiMethods.delete:
          resp = await dioInstance.delete(
            url,
            data: dataReq?.toJson(),
            queryParameters: queriesReq?.toJson(),
            options: options,
            cancelToken: cancelToken,
          );
          break;
      }
      developer.log("resp.data ${resp.data}");
      palResp = PalResponse(statusCode: resp.statusCode!, data: resp.data);
    } on DioException catch (e) {
      String? error;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          print("connectionTimeout");
          // TODO: Handle connection timeout
          break;
        case DioExceptionType.sendTimeout:
          print("sendTimeout");
          // TODO: Handle send timeout
          break;
        case DioExceptionType.receiveTimeout:
          print("receiveTimeout");
          // TODO: Handle receive timeout
          break;
        case DioExceptionType.badResponse:
          print("badResponse");
          // TODO: Handle bad response
          break;
        case DioExceptionType.cancel:
          print("cancel");
          // TODO: Handle cancel
          break;
        case DioExceptionType.unknown:
          print("unknown");
          error = "网络错误";
          // TODO: Handle unknown;
          break;
        case DioExceptionType.badCertificate:
          print("badCertificate");
          // TODO: Handle bad certificate
          break;
        case DioExceptionType.connectionError:
          print("connectionError");
          // TODO: Handle connection error
          break;
      }
      palResp = PalResponse(statusCode: 0, error: error);
    }
    developer.log("resp.data ${palResp.toString()}");
    var lastResp = await checkApiResponse<RESP>(palResp);
    // if (checkedResp == null) {
    //   return null;
    // } else {
    //   return await cleanApiResponse(checkedResp);
    // }
    if (lastResp.statusCode >= 200 && lastResp.statusCode < 300){
      lastResp = await cleanApiResponse<RESP>(lastResp);
    }else if (lastResp.statusCode == 404){
      lastResp.error = "未找到该资源";
    }
    // if (lastResp.statusCode == 404){
    //   lastResp.statusCode = 401;
    //
    // }
    return lastResp;
  }

  // Check api response hook
  @protected
  Future<PalResponse<T>> checkApiResponse<T>(PalResponse<T> palResp) async {
    // if (palResp.statusCode >= 400) {
    //   // DummyErrorResponse errResp = DummyErrorResponse.fromJson(resp.data);
    //   // print("Catch Error Response: ${errResp.toJson()}");
    //   // handleException(resp.data);
    //   return null;
    // }
    return palResp;
  }

  // Clean api response hook
  @protected
  Future<PalResponse<T>> cleanApiResponse<T>(PalResponse<T> palResp) async {
    print("${palResp.statusCode}");
    palResp.json = palResp.data != null ? palResp.data as Map<String, dynamic> : {};
    return palResp;
  }
}
