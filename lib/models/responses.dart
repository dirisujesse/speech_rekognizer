class TranscriptionResponse {
  final String message;
  final Object? data;
  final TranscriptionResponseType type;

  TranscriptionResponse({
    required this.message,
    this.type = TranscriptionResponseType.transcript,
    this.data,
  });

  bool get isError => type == TranscriptionResponseType.error;
  bool get isTranscript => type == TranscriptionResponseType.transcript;
  bool get isStartState => type == TranscriptionResponseType.started;
  bool get isCompletedState => type == TranscriptionResponseType.completed;
  bool get isState => isStartState || isCompletedState;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TranscriptionResponse) return false;
    return message == other.message &&
        data == other.data &&
        type == other.type &&
        isError == other.isError &&
        isTranscript == other.isTranscript &&
        isState == other.isState && isCompletedState == other.isCompletedState &&
        isStartState == other.isStartState;
  }

  @override
  int get hashCode => message.hashCode ^ data.hashCode ^ type.hashCode;
}

enum TranscriptionResponseType { transcript, error, started, completed }
