/// A Pune club mates can plan a night at.
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
  });

  final String id;
  final String name;
  final String area;
  final String address;

  Uri get mapsUrl => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$name, $address',
  });
}

const puneClubs = [
  Club(
    id: 'high-spirits',
    name: 'High Spirits Cafe',
    area: 'Koregaon Park',
    address: '35A/1, North Main Road, Koregaon Park, Pune, Maharashtra 411001',
  ),
  Club(
    id: 'l7',
    name: 'L7 Club & Lounge',
    area: 'Koregaon Park',
    address:
        'First Floor, Out of the World Building, Lane No. 7, Meera Nagar, '
        'Koregaon Park, Pune 411001',
  ),
  Club(
    id: 'plunge',
    name: 'Plunge',
    area: 'Koregaon Park',
    address:
        '3rd Floor, Jewel Square Mall, Vasani Nagar, Koregaon Park, Pune 411001',
  ),
  Club(
    id: 'penthouze',
    name: 'Penthouze Nightlife',
    area: 'Mundhwa & KP Annexe',
    address: 'Rooftop, Onyx Tower, next to Westin Hotel, Mundhwa Road, Pune',
  ),
  Club(
    id: 'euriska',
    name: 'Euriska',
    area: 'Mundhwa & KP Annexe',
    address: 'North Main Road, Koregaon Park Annexe, Mundhwa, Pune 411001',
  ),
  Club(
    id: 'xclusive',
    name: 'Xclusive Superclub Pune',
    area: 'Mundhwa & KP Annexe',
    address:
        'Zero One, Mundhwa Road, Pingale Wasti, Koregaon Park Annexe, '
        'Pune 411036',
  ),
  Club(
    id: '2bhk',
    name: '2BHK Diner & Key Club',
    area: 'The Mills, Sangamvadi',
    address:
        'Unit 7, The Mills, behind Sheraton Grand Pune, Raja Bahadur Mill '
        'Road, Pune 411001',
  ),
  Club(
    id: 'dimora',
    name: 'Dimora Dance & Kitchen',
    area: 'The Mills, Sangamvadi',
    address:
        'Unit 10, The Mills, Sai Radhe Road, behind Sheraton Grand Pune Bund '
        'Garden Hotel, Pune 411001',
  ),
  Club(
    id: 'acai',
    name: 'Açai Pune',
    area: 'The Mills, Sangamvadi',
    address:
        'B Wing, 2nd Floor, Raja Bahadur Mills, Station Road, behind Sheraton '
        'Grand Pune, Pune 411001',
  ),
  Club(
    id: 'mi-a-mi',
    name: 'Mi-A-Mi',
    area: 'Senapati Bapat Road',
    address: 'JW Marriott Hotel, Senapati Bapat Road, Pune 411053',
  ),
  Club(
    id: 'vault',
    name: 'Vault',
    area: 'Shivajinagar',
    address:
        'Senapati Bapat Road, Laxmi Society, Model Colony, Shivajinagar, '
        'Pune 411016',
  ),
  Club(
    id: 'backstage',
    name: 'Backstage Lounge & Bar',
    area: 'Viman Nagar',
    address:
        '2nd Floor, East Court, Phoenix Road, opposite Unicorn Store, Clover '
        'Park, Viman Nagar, Pune 411014',
  ),
  Club(
    id: 'lova',
    name: 'LOVA - By Escada',
    area: 'Viman Nagar',
    address:
        '4th Floor, Sai Apex, Viman Nagar Avenue 2, Clover Park, Pune 411014',
  ),
  Club(
    id: 'favela',
    name: 'Favela Pune',
    area: 'Hinjawadi',
    address:
        '922 & Terrace, Suratwala Mark Plazzo, opposite Indian Oil Petrol '
        'Pump, Hinjawadi, Pune 411057',
  ),
  Club(
    id: 'ice-n-fire',
    name: 'Ice N Fire Sky Lounge',
    area: 'Baner',
    address:
        '4th Floor, Kshitij Heights, Pashan Highway Side Road, next to '
        'Renault showroom, Baner, Pune 411069',
  ),
];

const clubTips = [
  'Check tonight’s timings, entry rules, cover charge and dress code with '
      'the club before you head out.',
  'Carry a valid government photo ID. Clubs check age at the door.',
  'Meet at the club entrance, not at someone’s home, and share your plan '
      'with a friend.',
  'Keep your drink in sight and skip drinks you did not see being poured.',
  'Plan your ride home before you go. Never drink and drive.',
  'If anything feels off, leave, and report or block in Clubmates.',
];

final _clubTag = RegExp(r'^\[club:([a-z0-9-]+)\]');

/// The chat message body for a club plan. The tag lets both apps render the
/// card; the rest reads fine anywhere the tag is not understood.
String clubMessage(Club club) =>
    '[club:${club.id}] Let’s go to ${club.name}, ${club.area}?';

Club? clubFromMessage(String? body) {
  if (body == null) return null;
  final id = _clubTag.firstMatch(body)?.group(1);
  if (id == null) return null;
  for (final club in puneClubs) {
    if (club.id == id) return club;
  }
  return null;
}

/// Message text with any club tag swapped for something readable.
String readableMessage(String body) {
  final club = clubFromMessage(body);
  if (club == null) return body;
  return 'Club plan: ${club.name}, ${club.area}';
}
