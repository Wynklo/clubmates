import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme.dart';

class ClubIcon extends StatelessWidget {
  const ClubIcon(this.name, {super.key, this.size = 22, this.color});

  final String name;
  final double size;
  final Color? color;

  static const _paths = <String, String>{
    'back': '<path d="M15 18l-6-6 6-6"/>',
    'club':
        '<circle cx="12" cy="8" r="3"/><path d="M6.5 19c.7-3 2.5-5 5.5-5s4.8 2 5.5 5M5 8h1M18 8h1"/>',
    'heart':
        '<path d="M20.8 5.8c-1.8-2-4.8-2-6.7-.2L12 7.7 9.9 5.6A4.6 4.6 0 003.2 12l8.8 8 8.8-8a4.6 4.6 0 000-6.2z"/>',
    'mates':
        '<circle cx="8" cy="9" r="3"/><circle cx="16" cy="9" r="3"/><path d="M2.8 19c.4-3 2.2-5 5.2-5 1.7 0 3 .6 4 1.8 1-1.2 2.3-1.8 4-1.8 3 0 4.8 2 5.2 5"/>',
    'profile':
        '<circle cx="12" cy="8" r="3.5"/><path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6"/>',
    'chevron': '<path d="M9 6l6 6-6 6"/>',
    'plus': '<path d="M12 5v14M5 12h14"/>',
    'check': '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    'close': '<path d="M7 7l10 10M17 7L7 17"/>',
    'camera':
        '<path d="M4 8h3l1.5-2h7L17 8h3v11H4z"/><circle cx="12" cy="13" r="3"/>',
    'location':
        '<path d="M19 10c0 5-7 10-7 10S5 15 5 10a7 7 0 1114 0z"/><circle cx="12" cy="10" r="2"/>',
  };

  @override
  Widget build(BuildContext context) {
    final paint = color ?? IconTheme.of(context).color ?? ClubColors.ink;
    final hex = paint.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final svg =
        '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#$hex" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${_paths[name]}</svg>
''';
    return SvgPicture.string(svg, width: size, height: size);
  }
}
