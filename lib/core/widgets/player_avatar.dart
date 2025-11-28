import 'dart:io';
import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  final String? photoPath;
  final String name;
  final double radius;

  const PlayerAvatar({
    super.key,
    this.photoPath,
    required this.name,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    
    if (photoPath != null && photoPath!.isNotEmpty) {
      try {
        final file = File(photoPath!);
        if (file.existsSync()) {
          avatar = CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
          );
        } else {
          avatar = _buildInitialsAvatar();
        }
      } catch (e) {
        avatar = _buildInitialsAvatar();
      }
    } else {
      avatar = _buildInitialsAvatar();
    }

    return avatar;
  }

  Widget _buildInitialsAvatar() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

