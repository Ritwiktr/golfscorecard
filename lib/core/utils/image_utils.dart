import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) return null;

      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage = File(image.path);
      final newPath = path.join(appDir.path, 'player_photos', fileName);
      
      // Create directory if it doesn't exist
      await Directory(path.dirname(newPath)).create(recursive: true);
      
      // Copy file to app directory
      final copiedFile = await savedImage.copy(newPath);
      return copiedFile.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) return null;

      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage = File(image.path);
      final newPath = path.join(appDir.path, 'player_photos', fileName);
      
      // Create directory if it doesn't exist
      await Directory(path.dirname(newPath)).create(recursive: true);
      
      // Copy file to app directory
      final copiedFile = await savedImage.copy(newPath);
      return copiedFile.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

