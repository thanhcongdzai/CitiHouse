class Apartment {
  final String id;
  final String title;
  final String subject;
  final String description;
  final int price;
  final String ward;
  final String commune;
  final String project;
  final String building;
  final int floor;
  final String apartmentNumber;
  final String displayCode;
  final String imageUrl;
  final String houseStatus;

  Apartment({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.price,
    required this.ward,
    required this.commune,
    required this.project,
    required this.building,
    required this.floor,
    required this.apartmentNumber,
    required this.displayCode,
    required this.imageUrl,
    required this.houseStatus,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      subject: json['subject'] as String? ?? 'No Subject',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      ward: json['location']?['ward'] as String? ?? '',
      commune: json['location']?['commune'] as String? ?? '',
      project: json['projectInfo']?['project'] as String? ?? '',
      building: json['projectInfo']?['building'] as String? ?? '',
      floor: json['projectInfo']?['floor'] as int? ?? 0,
      apartmentNumber: json['projectInfo']?['apartmentNumber'] as String? ?? '',
      displayCode: json['displayCode'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      houseStatus: json['houseStatus'] as String? ?? '',
    );
  }
}
