import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  final picker = ImagePicker();

  String? filePath;

  Future<Uint8List> selectGallery() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      imageQuality: 100,
    );
    try {
      return await pickedFile!.readAsBytes();
    } catch (e) {
      return throw ();
    }
  }


  Future<SelectedMedia> selectGallery2() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      imageQuality: 100,
    );
    try {
      return SelectedMedia(
        bytes: await pickedFile!.readAsBytes(),
        type: pickedFile.name,
      );
    } catch (e) {
      return throw ();
    }
  }

  Future<SelectedMedia> selectCamera2() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      requestFullMetadata: false,
      imageQuality: 100,
    );
    try {
      return SelectedMedia(
        bytes: await pickedFile!.readAsBytes(),
        type: pickedFile.name,
      );
    } catch (e) {
      return throw ();
    }
  }

  Future<SelectedMedia> selectVideoFromGallery() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    try {
      return SelectedMedia(
        bytes: await pickedFile!.readAsBytes(),
        type: pickedFile.name,
      );
    } catch (e) {
      return throw ();
    }
  }

  Future<SelectedMedia2> selectMedia() async {
    final pickedFile = await picker.pickMedia();

    if (pickedFile == null) {
      throw Exception('No file selected');
    }

    final bytes = await pickedFile.readAsBytes();
    String type;
    if (pickedFile.path.endsWith('.jpg') || pickedFile.path.endsWith('.jpeg') || pickedFile.path.endsWith('.png') || pickedFile.path.endsWith('.gif') || pickedFile.path.endsWith('.bmp') || pickedFile.path.endsWith('.webp')) {
      type = 'image';
    } else if (pickedFile.path.endsWith('.mp4') || pickedFile.path.endsWith('.mov') || pickedFile.path.endsWith('.avi') || pickedFile.path.endsWith('.mkv') || pickedFile.path.endsWith('.webm')) {
      type = 'video';
    } else {
      throw Exception('Unsupported media type');
    }


    return SelectedMedia2(
      bytes: bytes,
      type: type,
      name: pickedFile.name
    );
  }

  Future<SelectedMedia> selectVideoFromCamera() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.camera,maxDuration: Duration(seconds: 60));
    try {
      return SelectedMedia(
        bytes: await pickedFile!.readAsBytes(),
        type: pickedFile.name,
      );
    } catch (e) {
      return throw ();
    }
  }
}


class SelectedMedia {
  final Uint8List bytes;
  final String type; // 'image' یا 'video'

  SelectedMedia({
    required this.bytes,
    required this.type,
  });
}

class SelectedMedia2 {
  final Uint8List bytes;
  final String type;
  final String name; // 'image' یا 'video'

  SelectedMedia2({
    required this.bytes,
    required this.type,
    required this.name,
  });
}