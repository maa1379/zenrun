import 'package:just_audio/just_audio.dart';
import 'package:voice_note_kit/player/utils/audio_player_controller.dart';
import 'package:zenrun/core/network/api_helper.dart';

class MessageModel {
  int id;
  String senderEmail;
  String receiverEmail;
  String type;
  DateTime date;
  String message;
  bool isread;
  String link;
  int chatId;
  VoiceNotePlayerController playerController = VoiceNotePlayerController();

  MessageModel({
    required this.id,
    required this.senderEmail,
    required this.receiverEmail,
    required this.type,
    required this.date,
    required this.message,
    required this.isread,
    required this.link,
    required this.chatId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json["id"],
        senderEmail: json["sender_Email"],
        receiverEmail: json["receiver_Email"],
        type: json["type"],
        date: DateTime.parse(json["date"]),
        message: json["message"],
        isread: json["isread"],
        link: json["link"],
        chatId: json["chat_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sender_phone": senderEmail,
        "receiver_phone": receiverEmail,
        "type": type,
        "date": date.toIso8601String(),
        "message": message,
        "isread": isread,
        "link": link,
        "chat_id": chatId,
      };
}
