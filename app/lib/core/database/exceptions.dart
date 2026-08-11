class DuplicateNameException implements Exception {
  final String name;
  final String message;

  const DuplicateNameException(
    this.name, [
    this.message = 'A record with this name already exists.',
  ]);

  @override
  String toString() => 'DuplicateNameException: $message (name: $name)';
}
