library dio_util;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

enum ApiMethods {
  get,
  post,
  put,
  delete,
}


class BaseRequest {
  BaseRequest();

  Map<String, dynamic> toJson(){
    return {};
  }

  factory BaseRequest.fromJson(Map<String, dynamic> json){
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

class DioUtil {
  DioUtil();

  // General Dio instance
  final _dio = Dio();

  // Default interceptors
  final List<InterceptorsWrapper> _defaultInterceptors = [
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler){
        return handler.resolve(error.response!);
      })
  ];

  void handleException(Map<String, dynamic> exceptionRespData){
  }

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
  Future<Map<String, dynamic>?> makeHeaders()async{
    return {};
  }

  // Dynamic api host hook
  @protected
  Future<String> getApiHost()async{
    return "";
  }

  // Options maker hook
  Future<Options> makeOptions() async {
    return Options(headers: await makeHeaders());
  }

  // General api call
  Future<Map<String, dynamic>?> callApi<REQ extends BaseRequest>(ApiMethods method, String path,
      { REQ? dataReq, REQ? queriesReq, CancelToken? cancelToken,
        void Function(int, int)? onReceiveProgress, void Function(int, int)? onSendProgress}) async {

    Options options = await makeOptions();
    var apiHost = await getApiHost();
    String url = "$apiHost$path";
    Response resp;

    switch (method) {
      case ApiMethods.get:
        resp = await dioInstance.get(url,
            data: dataReq?.toJson(), queryParameters: queriesReq?.toJson(),
            options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
        break;
      case ApiMethods.post:
        resp = await dioInstance.post(url,
            data: dataReq?.toJson(), queryParameters: queriesReq?.toJson(),
            options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
        break;
      case ApiMethods.put:
        resp = await dioInstance.put(url,
            data: dataReq?.toJson(), queryParameters: queriesReq?.toJson(),
            options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
        break;
      case ApiMethods.delete:
        resp = await dioInstance.delete(
          url,
          data: dataReq?.toJson(), queryParameters: queriesReq?.toJson(),
          options: options, cancelToken: cancelToken,);
        break;
    }

    var checkedResp = await checkApiResponse(resp);
    if (checkedResp == null){
      return null;
    }else{
      return await cleanApiResponse(checkedResp);
    }
  }

  // Check api response hook
  @protected
  Future<Response?> checkApiResponse(Response resp)async{
    if (resp.statusCode! >= 400){
      // DummyErrorResponse errResp = DummyErrorResponse.fromJson(resp.data);
      // print("Catch Error Response: ${errResp.toJson()}");
      handleException(resp.data);
      return null;
    }
    return resp;
  }

  // Clean api response hook
  @protected
  Future<Map<String, dynamic>> cleanApiResponse(Response resp)async{
    return resp.data;
  }
}
