import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/user_service.dart';
import 'profile_modal.dart';

class UserAvatar extends ConsumerWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const UserAvatar({
    super.key,
    this.size = 44,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final avatarColor =
        Color(int.parse(user.avatarColorHex.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () => showProfileModal(context, ref),
      child: Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: avatarColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: avatarColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
