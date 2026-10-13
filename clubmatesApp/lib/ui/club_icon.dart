import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

class ClubIcon extends StatelessWidget {
  const ClubIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color,
    this.filled = false,
  });

  final String name;
  final double size;
  final Color? color;
  final bool filled;

  static const _paths = <String, String>{
    'back': '<path d="M15 18l-6-6 6-6"/>',
    'club':
        '<path d="M4.6 4.4h14.8M4.6 4.4L12 12.6 19.4 4.4M12 12.6v5.8M7.8 18.4h8.4"/>',
    'heart':
        '<path d="M12 19.7c-.35-.22-6.55-4.05-7.95-7.45C2.7 9.45 3.55 6.7 6.15 6c1.45-.4 2.95.1 3.8 1.25L12 9.05l2.05-1.8c.85-1.15 2.35-1.65 3.8-1.25 2.6.7 3.45 3.45 2.1 6.25C18.55 15.65 12.35 19.48 12 19.7z"/>',
    'mates':
        '<circle cx="8.25" cy="9" r="2.75"/><circle cx="16.25" cy="9.6" r="2.35"/><path d="M2.75 19c.45-3.55 2.3-5.25 5.5-5.25s5.05 1.7 5.5 5.25M13.25 14.3c.85-.8 1.85-1.2 3-1.2 2.8 0 4.45 1.55 4.85 4.75"/>',
    'tune':
        '<path d="M4 7h9M18 7h2M4 17h2M11 17h9"/><circle cx="15.5" cy="7" r="2.25"/><circle cx="8.5" cy="17" r="2.25"/>',
    'profile':
        '<circle cx="12" cy="7.7" r="3.15"/><path d="M5.45 19.55c.8-3.65 3.1-5.5 6.55-5.5s5.75 1.85 6.55 5.5c.15.55-.25 1.05-.85 1.05H6.3c-.6 0-1-.5-.85-1.05z"/>',
    'chevron': '<path d="M9 6l6 6-6 6"/>',
    'plus': '<path d="M12 5v14M5 12h14"/>',
    'check': '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    'close': '<path d="M7 7l10 10M17 7L7 17"/>',
    'camera':
        '<path d="M4 8h3l1.5-2h7L17 8h3v11H4z"/><circle cx="12" cy="13" r="3"/>',
    'location':
        '<path d="M19 10c0 5-7 10-7 10S5 15 5 10a7 7 0 1114 0z"/><circle cx="12" cy="10" r="2"/>',
    'shield':
        '<path d="M12 3.5l7 2.7v5.2c0 4.3-2.3 7.4-7 9.1-4.7-1.7-7-4.8-7-9.1V6.2z"/>',
    'send': '<path d="M4 5l16 7-16 7 3-7z"/><path d="M7 12h13"/>',
    'message':
        '<path d="M5.2 7.2h13.6a1.8 1.8 0 011.8 1.8v6.1a1.8 1.8 0 01-1.8 1.8H9.4L5.2 20.4V9a1.8 1.8 0 011.8-1.8z"/>',
  };

  @override
  Widget build(BuildContext context) {
    final paint = color ?? IconTheme.of(context).color ?? ClubColors.ink;
    final hex = paint.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final drawFilled = filled && name != 'club' && name != 'mates';
    final stroke = name == 'mates' ? 1.85 : 1.8;
    final svg = drawFilled
        ? '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#$hex">${_paths[name]}</svg>
'''
        : '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#$hex" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">${_paths[name]}</svg>
''';
    return SvgPicture.string(svg, width: size, height: size);
  }
}
