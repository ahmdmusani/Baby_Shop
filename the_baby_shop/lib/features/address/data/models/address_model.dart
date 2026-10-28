class AddressModel {
  final String id;
  final String title;
  final String name;
  final String addressLine;
  final String phone;

  AddressModel({
    required this.id,
    required this.title,
    required this.name,
    required this.addressLine,
    required this.phone,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map, String docId) {
    return AddressModel(
      id: docId,
      title: map['title'] ?? '',
      name: map['name'] ?? '',
      addressLine: map['addressLine'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': name,
      'addressLine': addressLine,
      'phone': phone,
    };
  }
}
