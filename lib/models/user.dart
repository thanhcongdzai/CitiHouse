class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String dob;
  final String cccd;
  final String gender;
  final String address;
  final String? bankAccount;
  final bool isActive;
  final String role;
  final String email;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.dob,
    required this.cccd,
    required this.gender,
    required this.address,
    this.bankAccount,
    required this.isActive,
    required this.role,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      cccd: json['cccd'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      bankAccount: json['bankAccount'],
      isActive: json['isActive'] ?? true,
      role: json['role'] ?? 'User',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'dob': dob,
      'cccd': cccd,
      'gender': gender,
      'address': address,
      'bankAccount': bankAccount,
      'isActive': isActive,
      'role': role,
      'email': email,
    };
  }
}
