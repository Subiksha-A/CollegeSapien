class EventItem {
  final String eventName;
  final String location;
  final String communityName;
  final String communityLogo;
  final String eventLink;
  final String eventDate;

  const EventItem({
    required this.eventName,
    required this.location,
    required this.communityName,
    required this.communityLogo,
    required this.eventLink,
    required this.eventDate,
  });

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        eventName: j['eventName'] as String? ?? '',
        location: j['location'] as String? ?? '',
        communityName: j['communityName'] as String? ?? '',
        communityLogo: j['communityLogo'] as String? ?? '',
        eventLink: j['eventLink'] as String? ?? '',
        eventDate: j['eventDate'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'eventName': eventName,
        'location': location,
        'communityName': communityName,
        'communityLogo': communityLogo,
        'eventLink': eventLink,
        'eventDate': eventDate,
      };
}
