class VaultItem {
  const VaultItem({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.website,
    required this.category,
    this.notes = '',
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String username;
  final String password;
  final String website;
  final String category;
  final String notes;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toEncryptedJson() => {
        'title': title,
        'username': username,
        'password': password,
        'website': website,
        'category': category,
        'notes': notes,
        'favorite': favorite,
      };

  factory VaultItem.fromEncryptedJson(
    Map<String, dynamic> json, {
    required int id,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return VaultItem(
      id: id,
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      website: json['website'] as String? ?? '',
      category: json['category'] as String? ?? '个人',
      notes: json['notes'] as String? ?? '',
      favorite: json['favorite'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  VaultItem copyWith({
    int? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? category,
    String? notes,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
