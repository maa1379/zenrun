import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';


/// مدل استاندارد پاسخ API
class ApiResult<T> {
  final bool isSuccess;
  final int statusCode;
  final String? message;
  final T? data;

  ApiResult({
    required this.isSuccess,
    required this.statusCode,
    this.message,
    this.data,
  });

  factory ApiResult.success(T data, {int code = 200}) {
    return ApiResult(isSuccess: true, statusCode: code, data: data);
  }

  factory ApiResult.failure(String message, {int code = 500, T? data}) {
    return ApiResult(
      isSuccess: false,
      statusCode: code,
      message: message,
      data: data,
    );
  }
}

class ApiHelper {
  // --- Constants ---
  static const String _baseUrl = 'https://zenrun.ir/';
  static const String _uploadUrl = "https://zenrun.zenrun-uploader.workers.dev/uploadCenter";

  static const Duration _timeout = Duration(seconds: 30);
  static const int _defaultRetry = 2;

  static Codec<String, String> stringToBase64 = utf8.fuse(base64);

  // --- Main API Methods ---

  static Future<ApiResult> post(
    String endpoint, {
    Map<String, dynamic> queryParams = const {},
    int retryCount = _defaultRetry,
        bool? disableLoading,
  }) async {
    int attempts = 0;

    while (attempts < retryCount) {
      attempts++;
      try {
        final rawQuery = mapToRawQuery(queryParams);
        final uri = Uri.parse("$_baseUrl$endpoint").replace(query: rawQuery);

        // 2. آماده‌سازی Body و Token طبق لاجیک پروژه
        final body = await _buildBodyForEndpoint(endpoint);

        _logRequest(uri.toString(), body);
        if(disableLoading != true) showLoading();
        // 3. ارسال درخواست
        final response = await http.post(uri, body: body).timeout(_timeout);
        if(disableLoading != true) dismissLoading();
        _logResponse(uri.toString(), response);

        if (response.body.toString().replaceAll('"', "").startsWith("-") == false) {
          try {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            return ApiResult.success(data);
          } catch (e) {
            return ApiResult.failure("Invalid response format");
          }
        } else {
          // Server returned an explicit error (e.g. "-1") — no point retrying.
          return ApiResult.failure(
            "Server error: ${response.body}",
            code: response.statusCode,
          );
        }
      } catch (e) {
        debugPrint("Attempt $attempts error: $e");
        if (attempts >= retryCount) {
          return ApiResult.failure("Network Error: $e");
        }
      }

      if (attempts < retryCount) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return ApiResult.failure("Failed after $retryCount attempts");
  }

  static String mapToRawQuery(Map<String, dynamic> params) {
    return params.entries.map((e) => "${e.key}=${e.value}").join("&");
  }

  // --- Upload Methods ---

  /// آپلود فایل عمومی
  static Future<String?> uploadFile(Uint8List file, {String? fileName}) async {
    return _baseUploader(file, fileName: fileName);
  }

  static Future<String?> _baseUploader(
    Uint8List fileBytes, {
    String? fileName,
  }) async {
    try {
      showLoading();
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      dismissLoading();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']?.toString();
      } else {
        debugPrint("Upload Failed: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      dismissLoading();
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// مدیریت لاجیک خاص توکن‌ها بر اساس Endpoint
  static Future<Map<String, String>?> _buildBodyForEndpoint(
    String endpoint,
  ) async {
    if (endpoint == "LoginRegister.aspx") {
      return null;
    } else {
      final userToken = await PrefHelpers.getToken();
      final token = stringToBase64.encode(userToken ?? "");
      return {"Token": token};
    }
  }

  static void _logRequest(String url, dynamic body) {
    if (kDebugMode) {
      print("🔵 POST REQ: $url");
      if (body != null) print("📦 Body: $body");
    }
  }

  static void _logResponse(String url, http.Response response) {
    if (kDebugMode) {
      print(
        response.statusCode == 200
            ? "🟢 SUCCESS ($url)"
            : "🔴 FAIL ${response.statusCode} ($url)",
      );
      print("Response: ${response.body}");
    }
  }

  static void showLoading() {
    // EasyLoading.show(
    //   indicator: Lottie.asset("assets/anim/animLoading.json", width: 100),
    //   dismissOnTap: true,
    // );
  }

  static void dismissLoading() {
    // No-op: showLoading is disabled, so nothing to dismiss.
    // Do NOT call EasyLoading.dismiss here — it would close loading
    // indicators started by other parts of the app.
  }
}
