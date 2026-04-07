class Apartment {
  final String id;
  final String title;
  final String subject;
  final String description;
  final int price;
  final String ward;
  final String commune;
  final String project;
  final String? projectId;
  final String building;
  final int floor;
  final String apartmentNumber;
  final String displayCode;
  final String imageUrl;
  final String houseStatus;
  final String finalApprove;
  final Map<String, dynamic>? verifications;
  final String? postedBy;
  final Map<String, dynamic>? owner;
  final int bedRoom;
  final int livingRoom;
  final int diningRoom;
  final int kitchen;
  final int bathRoom;
  final double? area;

  Apartment({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.price,
    required this.ward,
    required this.commune,
    required this.project,
    this.projectId,
    required this.building,
    required this.floor,
    required this.apartmentNumber,
    required this.displayCode,
    required this.imageUrl,
    required this.houseStatus,
    this.finalApprove = '',
    this.verifications,
    this.postedBy,
    this.owner,
    this.bedRoom = 0,
    this.livingRoom = 0,
    this.diningRoom = 0,
    this.kitchen = 0,
    this.bathRoom = 0,
    this.area,
  });

  static String _parseImageUrl(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .join(',');
    }
    return value.toString().trim();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    if (value is Map) {
      final numberLong = value['\$numberLong']?.toString();
      if (numberLong != null) return int.tryParse(numberLong) ?? 0;
      final numberInt = value['\$numberInt']?.toString();
      if (numberInt != null) return int.tryParse(numberInt) ?? 0;
    }
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  factory Apartment.fromJson(Map<String, dynamic> json) {
    final String resolvedImageUrl = _parseImageUrl(
      json['userImageUrl'] ?? json['imageUrl'],
    );

    return Apartment(
      id: json['id']?.toString() ?? json['_id']?['\$oid']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? 'No Title',
      subject: json['subject'] as String? ?? 'No Subject',
      description: json['description'] as String? ?? '',
      price: _parseInt(json['price']),
      ward: (json['location']?['ward'] as String? ?? '').trim(),
      commune: (json['location']?['commune'] as String? ?? '').trim(),
      project: (json['projectInfo']?['project'] as String? ?? '').trim(),
      projectId: json['projectInfo']?['projectId']?.toString() ?? '',
      building: (json['projectInfo']?['building'] as String? ?? '').trim(),
      floor: _parseInt(json['projectInfo']?['floor']),
      apartmentNumber: json['projectInfo']?['apartmentNumber'] as String? ?? '',
      displayCode: json['displayCode'] as String? ?? '',
      imageUrl: resolvedImageUrl,
      houseStatus: json['houseStatus'] as String? ?? '',
      finalApprove: json['finalApprove']?.toString() ?? '',
      verifications: json['verifications'] as Map<String, dynamic>?,
      postedBy: json['postedBy']?.toString(),
      owner: json['owner'] is Map
          ? Map<String, dynamic>.from(json['owner'] as Map)
          : null,
      bedRoom: _parseInt(json['bedRoom']),
      livingRoom: _parseInt(json['livingRoom']),
      diningRoom: _parseInt(json['diningRoom']),
      kitchen: _parseInt(json['kitchen']),
      bathRoom: _parseInt(json['bathRoom']),
      area: _parseDouble(json['area']),
    );
  }
}
