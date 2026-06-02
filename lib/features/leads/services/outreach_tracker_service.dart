import 'package:flutter/foundation.dart';

import '../models/lead_outreach_state.dart';

class OutreachTrackerService {
  OutreachTrackerService._();

  static final OutreachTrackerService instance = OutreachTrackerService._();

  final ValueNotifier<Map<String, LeadOutreachState>> states =
      ValueNotifier<Map<String, LeadOutreachState>>(const {});

  LeadOutreachState stateFor(String leadId) {
    return states.value[leadId] ?? const LeadOutreachState();
  }

  void markContacted(
    String leadId, {
    required String channel,
    DateTime? at,
  }) {
    final current = stateFor(leadId);
    _update(
      leadId,
      current.copyWith(
        stage: LeadPipelineStage.contacted,
        lastContactedAt: at ?? DateTime.now(),
        channel: channel,
        clearReply: true,
      ),
    );
  }

  void setReplyState(String leadId, bool? replied) {
    final current = stateFor(leadId);
    final nextStage = replied == true
        ? LeadPipelineStage.replied
        : (current.stage == LeadPipelineStage.closed
            ? LeadPipelineStage.closed
            : current.stage);
    _update(
      leadId,
      current.copyWith(
        stage: nextStage,
        replied: replied,
      ),
    );
  }

  void setStage(String leadId, LeadPipelineStage stage) {
    final current = stateFor(leadId);
    _update(
      leadId,
      current.copyWith(
        stage: stage,
        replied: stage == LeadPipelineStage.replied
            ? true
            : (stage == LeadPipelineStage.closed ? true : current.replied),
      ),
    );
  }

  void _update(String leadId, LeadOutreachState next) {
    states.value = {
      ...states.value,
      leadId: next,
    };
  }
}
