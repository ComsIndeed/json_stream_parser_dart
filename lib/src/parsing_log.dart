abstract class ParsingLog {
  String get message;
}

class ParsingInfo extends ParsingLog {
  @override
  final String message;

  ParsingInfo(this.message);
}

class ParsingWarning extends ParsingLog {
  @override
  final String message;

  ParsingWarning(this.message);
}

class ParsingError extends ParsingLog {
  @override
  final String message;

  ParsingError(this.message);
}
