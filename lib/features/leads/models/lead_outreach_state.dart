enum LeadPipelineStage { fresh, contacted, replied, closed }

class LeadOutreachState {
  final LeadPipelineStage stage;
  final DateTime? lastContactedAt;
  final String? channel;
  final bool? replied;

  const LeadOutreachState({
    this.stage = LeadPipelineStage.fresh,
    this.lastContactedAt,
    this.channel,
    this.replied,
  });

  LeadOutreachState copyWith({
    LeadPipelineStage? stage,
    DateTime? lastContactedAt,
    String? channel,
    bool? replied,
    bool clearReply = false,
  }) {
    return LeadOutreachState(
      stage: stage ?? this.stage,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      channel: channel ?? this.channel,
      replied: clearReply ? null : (replied ?? this.replied),
    );
  }
}
