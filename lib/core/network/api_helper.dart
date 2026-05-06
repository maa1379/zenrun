import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http_parser/http_parser.dart'; // <--- اضافه شود
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../PrefHelper/PrefHelpers.dart';
import 'DataState.dart';

class ApiResult {
  bool? isDone;
  String? requestedMethod;
  dynamic data;
  String? message;
  var statusCode;

  ApiResult({
    this.isDone,
    this.requestedMethod,
    this.data,
    this.message,
    this.statusCode,
  });
}

class ApiHelper {
  static const String baseUrl = 'https://zenrun.ir/API/';
  static const String baseUrl2 = 'https://zenrun.ai/ImageStorage/';
  static const String aiBaseUrl =
      'https://voiceapp-708846608306.us-central1.run.app/';
  static Codec<String, String> stringToBase64 = utf8.fuse(base64);

  static String mapToRawQuery(Map<String, dynamic> params) {
    return params.entries.map((e) => "${e.key}=${e.value}").join("&");
  }

  static Future<ApiResult> makeGetRequest({
    String? path,
    Map<String, dynamic> queryParameters = const {},
    int retryCount = 3, // تعداد دفعات تلاش مجدد
  }) async {
    ApiResult apiResult = ApiResult();
    int attempts = 0;

    while (attempts < retryCount) {
      attempts++;

      final user = await PrefHelpers.getToken();
      final token = stringToBase64.encode(user ?? "");

      print("Full URL: ${baseUrl + path.toString()}");
      print("Query Params: $queryParameters");
      print("Token: $token");

      final rawQuery = mapToRawQuery(queryParameters);
      try {
        // ارسال درخواست HTTP
        http.Response response = await http.post(
          Uri.parse("$baseUrl$path/?$rawQuery"),
          body: (path == "LoginRegister.aspx")
              ? null
              : (path == "ContactUs.aspx")
              ? {"Token": "YWRtaW4="}
              : {"Token": token},
        );

        print("Full URL: ${baseUrl + path.toString()}");
        print("Status Code: ${response.statusCode}");
        print("Raw Body: ${response.body}");

        if (response.statusCode == 200) {
          // اگر پاسخ 200 باشد، داده‌ها را پردازش کن
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          print("Decoded data: $data");
          apiResult.data = data;
          apiResult.statusCode = response.statusCode;
          return apiResult; // در صورتی که داده‌ها درست بودند، نتیجه را باز می‌گرداند
        } else {
          print("Received non-200 status code: ${response.statusCode}");
          // اگر وضعیت پاسخ غیر از 200 باشد، تلاش دوباره را شروع می‌کنیم
        }
      } catch (e) {
        print("Error in request: $e");
        apiResult.data = {"error": "Request failed"};
      }

      if (attempts < retryCount) {
        print("Retrying... Attempt $attempts/$retryCount");
        await Future.delayed(Duration(seconds: 2)); // تاخیر قبل از تلاش مجدد
      }
    }

    // اگر بعد از تعداد تلاش‌های مشخص، هنوز داده‌ای دریافت نشد، خطا را برمی‌گرداند
    apiResult.data = {
      "error": "Failed to get valid response after $retryCount attempts",
    };
    apiResult.statusCode = 500; // وضعیتی برای خطای سرور
    return apiResult;
  }

  static Future<ApiResult> makePostForAi({
    String? path,
    Map<String, dynamic> body = const {},
    int retryCount = 3, // تعداد تلاش‌های مجدد
  }) async {
    ApiResult apiResult = ApiResult();
    int attempts = 0;

    while (attempts < retryCount) {
      attempts++;
      print("Full URL: ${aiBaseUrl + path.toString()}");
      print("Body: $body");

      try {
        http.Response response = await http.post(
          Uri.parse("$aiBaseUrl$path"),
          body: json.encode(body),
          headers: {'Content-Type': 'application/json'},
        );
        print("Full URL: ${aiBaseUrl + path.toString()}");
        print("Status Code: ${response.statusCode}");
        print("Body: $body");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Decoded data: $data");
          apiResult.data = data;
          apiResult.statusCode = response.statusCode;
          return apiResult;
        } else {
          print("Received non-200 status code: ${response.statusCode}");
        }
      } catch (e) {
        print("Error in request: $e");
        apiResult.data = {"error": "Request failed"};
      }

      if (attempts < retryCount) {
        print("Retrying... Attempt $attempts/$retryCount");
        await Future.delayed(Duration(seconds: 2)); // تاخیر قبل از تلاش مجدد
      }
    }

    apiResult.statusCode = 500; // خطای سرور
    apiResult.data = {
      "error": "Failed to get valid response after $retryCount attempts",
    };
    return apiResult;
  }

  static Future<String> uploaderWeb(Uint8List file, String fileName) async {
    List<int> list = file.cast();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://zenrun.zenrun-uploader.workers.dev/uploadCenter"),
    );

    request.files.add(
      http.MultipartFile.fromBytes('file', list, filename: fileName,
          contentType: fileName.endsWith("mp4") ||fileName.endsWith("mov") ?MediaType('video', 'mp4'):MediaType('image', 'png')
      ),
    );


    http.StreamedResponse response = await request.send();
    var res = await http.Response.fromStream(response);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['url'].toString();
    } else {
      return "error";
    }
  }

}

String fixDoubleSlashes(String url) {
  return url.replaceAllMapped(RegExp(r'([^:])//+'), (match) {
    return '${match.group(1)}/';
  });
}
