import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';
import '../../../services/socket_service.dart';
import '../chat_screens/call_screen.dart';
import 'chat_global_controller.dart';

class CallController extends GetxController {
  final SocketService socketService = Get.find<SocketService>();
  final ChatGlobalController globalController = Get.find<ChatGlobalController>();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // رندرها (نمایش دهنده ویدیو)
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // وضعیت‌ها
  var isIncoming = false.obs;       // آیا تماس ورودی است؟
  var isCallActive = false.obs;     // آیا صفحه تماس باز است؟
  var callStatus = "Wait for connection...".obs;

  // کنترل‌های مدیا
  var isMicMuted = false.obs;
  var isSpeakerOn = false.obs;
  var isCameraOff = false.obs;
  var isRemoteVideoConnected = false.obs; // برای جلوگیری از صفحه سیاه

  // مشخصات طرف مقابل
  int? targetId;
  String? targetName;
  String? targetAvatar;

  bool _isCallEnded = false;

  // صف کاندیداها (برای حل مشکل اتصال)
  final List<RTCIceCandidate> _candidateQueue = [];
  bool _remoteDescriptionSet = false;

  // سرورهای STUN برای عبور از NAT (خیلی مهم برای کار کردن تماس)
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ]
  };

  @override
  void onInit() {
    super.onInit();
    initRenderers();
    _listenToSocketEvents(); // گوش دادن دائمی به رویدادها
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // چک کردن مجوزها
  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
      return true;
    } else {
      Get.snackbar("خطا", "دسترسی دوربین و میکروفون لازم است", snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ============================================
  // 1. شروع تماس (Caller)
  // ============================================
  Future<void> startCall(int tId, String tName, String? tAvatar) async {
    if (!await _checkPermissions()) return;

    targetId = tId;
    targetName = tName;
    targetAvatar = tAvatar;

    isIncoming.value = false;
    isCallActive.value = true;
    callStatus.value = "Calling...";
    _remoteDescriptionSet = false;
    _candidateQueue.clear();

    Get.toNamed("/call_screen");

    await _initPeerConnection();

    // ساخت Offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // ارسال درخواست به سرور (دیگه اسم خودمون رو نمیفرستیم، سرور پیدا میکنه)
    socketService.socket?.emit("call_user", {
      "userToCall": targetId,
      "signalData": offer.toMap(),
    });
  }

  // ============================================
  // 2. دریافت تماس (Receiver) - فراخوانی از GlobalController
  // ============================================
  Future<void> handleIncomingCall(Map<String, dynamic> data) async {
    if (!await _checkPermissions()) {
      // اگر دسترسی نداشت، تماس رو رد کن
      socketService.socket?.emit("end_call", {"to": data['fromId']});
      return;
    }

    targetId = data['fromId'];
    targetName = data['fromName'];     // الان دیگه نام واقعی میاد
    targetAvatar = data['fromAvatar']; // الان دیگه عکس واقعی میاد
    var signal = data['signal'];

    isIncoming.value = true;
    isCallActive.value = true;
    callStatus.value = "Open Call...";
    _remoteDescriptionSet = false;
    _candidateQueue.clear();

    Get.to(() => const CallScreen());

    await _initPeerConnection();

    // ست کردن Offer طرف مقابل
    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], signal['type']));

    _remoteDescriptionSet = true;
    _processCandidateQueue();
  }

  // ============================================
  // 3. قبول تماس (Answer)
  // ============================================
  Future<void> acceptCall() async {
    isIncoming.value = false;
    callStatus.value = "Connecting...";

    try {
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      socketService.socket?.emit("answer_call", {
        "signal": answer.toMap(),
        "to": targetId,
      });
    } catch (e) {
      print("Error acceptCall: $e");
    }
  }

  // ============================================
  // 4. تنظیمات WebRTC
  // ============================================
  Future<void> _initPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // روشن کردن اسپیکر به صورت پیشفرض
      if (_localStream!.getAudioTracks().isNotEmpty) {
        _localStream!.getAudioTracks()[0].enableSpeakerphone(true);
        isSpeakerOn.value = true;
      }

    } catch (e) {
      print("Error getUserMedia: $e");
      return;
    }

    // ارسال ICE Candidate
    _peerConnection!.onIceCandidate = (candidate) {
      if (targetId != null) {
        socketService.socket?.emit("ice_candidate", {
          "to": targetId,
          "candidate": candidate.toMap(),
        });
      }
    };

    // دریافت تصویر طرف مقابل
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        isRemoteVideoConnected.value = true;
        callStatus.value = "Connected";
      }
    };

    // وقتی تصویر قطع میشه
    _peerConnection!.onRemoveStream = (stream) {
      isRemoteVideoConnected.value = false;
    };
  }

  void _listenToSocketEvents() {
    // جلوگیری از لیسنرهای تکراری
    socketService.socket?.off("call_accepted");
    socketService.socket?.off("ice_candidate");
    socketService.socket?.off("call_ended");
    socketService.socket?.off("call_failed");

    // تماس توسط طرف مقابل قبول شد
    socketService.socket?.on("call_accepted", (data) async {
      var signal = data['signal'];
      await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(signal['sdp'], signal['type']));

      _remoteDescriptionSet = true;
      _processCandidateQueue();
      callStatus.value = "Connecting...";
    });

    // دریافت ICE Candidate
    socketService.socket?.on("ice_candidate", (data) async {
      var cData = data['candidate'];
      RTCIceCandidate candidate = RTCIceCandidate(
          cData['candidate'], cData['sdpMid'], cData['sdpMLineIndex']);

      if (_remoteDescriptionSet && _peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _candidateQueue.add(candidate);
      }
    });

    // تماس قطع شد
    socketService.socket?.on("call_ended", (_) {
      endCall(remoteEnded: true);
    });

    // کاربر آفلاین بود یا خطا
    socketService.socket?.on("call_failed", (data) {
      Get.snackbar("ناموفق", "کاربر در دسترس نیست");
      endCall(remoteEnded: true);
    });
  }

  void _processCandidateQueue() async {
    for (var candidate in _candidateQueue) {
      await _peerConnection!.addCandidate(candidate);
    }
    _candidateQueue.clear();
  }

  // ============================================
  // 5. پایان دادن و ابزارها
  // ============================================

  void rejectCall() {
    endCall();
  }

  void endCall({bool remoteEnded = false}) {
    // if (_isCallEnded) return;
    _isCallEnded = true;

    if (!remoteEnded && targetId != null) {
      socketService.socket?.emit("end_call", {"to": targetId});
    }

    // try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _peerConnection?.close();
      _peerConnection = null;
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    // } catch (e) {
    //   print("Close error: $e");
    // }

    if (Get.isRegistered<CallController>()) {
      Get.back(); // بستن صفحه
      // پاک کردن کنترلر با تاخیر کم
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.delete<CallController>(force: true);
      });
    }
  }

  // متدهای تاگل (دوربین، میکروفون، اسپیکر)
  void toggleMic() {
    isMicMuted.toggle();
    if (_localStream != null) {
      _localStream!.getAudioTracks()[0].enabled = !isMicMuted.value;
    }
  }

  void toggleSpeaker() {
    isSpeakerOn.toggle();
    if (_localStream != null) {
      _localStream!.getAudioTracks()[0].enableSpeakerphone(isSpeakerOn.value);
    }
  }

  void toggleCamera() {
    isCameraOff.toggle();
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      _localStream!.getVideoTracks()[0].enabled = !isCameraOff.value;
    }
  }

  void switchCamera() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  @override
  void onClose() {
    if (!_isCallEnded) endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }
}