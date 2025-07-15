enum RecipientType { todos, professores }

RecipientType recipientTypeFromString(String value) {
  return RecipientType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => RecipientType.todos,
  );
}

String recipientTypeToString(RecipientType recipient) {
  return recipient.name;
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final RecipientType recipient;
  final List<Map<String, dynamic>> files;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.recipient,
    required this.files,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'recipient': recipient.name,
      'files': files,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> data, String id) {
    return Announcement(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      recipient: recipientTypeFromString(data['recipient'] ?? 'todos'),
      files: List<Map<String, dynamic>>.from(data['files'] ?? []),
    );
  }
}
