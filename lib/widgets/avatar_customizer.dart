import 'package:flutter/material.dart';
import '../models/avatar.dart';
import 'avatar_renderer.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarCustomizer extends StatelessWidget {
  final Avatar avatar;
  final ValueChanged<Avatar> onChanged;

  const AvatarCustomizer({
    super.key,
    required this.avatar,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black, width: 3.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Cycle Colors Left
              _buildArrowButton(
                icon: Icons.arrow_back,
                onPressed: () {
                  final newColorIdx = (avatar.bodyColorIndex - 1 + Avatar.avatarColors.length) % Avatar.avatarColors.length;
                  onChanged(avatar.copyWith(bodyColorIndex: newColorIdx));
                },
              ),
              const SizedBox(width: 12),
              
              // 2. Avatar Display
              AvatarRenderer(avatar: avatar, size: 90.0),
              
              const SizedBox(width: 12),
              // 3. Cycle Colors Right
              _buildArrowButton(
                icon: Icons.arrow_forward,
                onPressed: () {
                  final newColorIdx = (avatar.bodyColorIndex + 1) % Avatar.avatarColors.length;
                  onChanged(avatar.copyWith(bodyColorIndex: newColorIdx));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row for Eyes Selection
          _buildSelectionRow(
            label: "EYES",
            value: avatar.eyesIndex + 1,
            onPrev: () {
              final newEyesIdx = (avatar.eyesIndex - 1 + 10) % 10;
              onChanged(avatar.copyWith(eyesIndex: newEyesIdx));
            },
            onNext: () {
              final newEyesIdx = (avatar.eyesIndex + 1) % 10;
              onChanged(avatar.copyWith(eyesIndex: newEyesIdx));
            },
          ),
          const SizedBox(height: 8),

          // Row for Mouth Selection
          _buildSelectionRow(
            label: "MOUTH",
            value: avatar.mouthIndex + 1,
            onPrev: () {
              final newMouthIdx = (avatar.mouthIndex - 1 + 10) % 10;
              onChanged(avatar.copyWith(mouthIndex: newMouthIdx));
            },
            onNext: () {
              final newMouthIdx = (avatar.mouthIndex + 1) % 10;
              onChanged(avatar.copyWith(mouthIndex: newMouthIdx));
            },
          ),
          const SizedBox(height: 16),

          // Randomize Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => onChanged(Avatar.random()),
              icon: const Icon(Icons.casino, color: Colors.white),
              label: Text(
                'RANDOMIZE',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e90ff),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black, width: 3.0),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectionRow({
    required String label,
    required int value,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Row(
          children: [
            _buildArrowButton(icon: Icons.chevron_left, onPressed: onPrev, mini: true),
            Container(
              alignment: Alignment.center,
              width: 50,
              child: Text(
                '$value',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            _buildArrowButton(icon: Icons.chevron_right, onPressed: onNext, mini: true),
          ],
        )
      ],
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool mini = false,
  }) {
    return Container(
      width: mini ? 32 : 40,
      height: mini ? 32 : 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(mini ? 8 : 12),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: Colors.black, size: mini ? 18 : 22),
        onPressed: onPressed,
      ),
    );
  }
}
