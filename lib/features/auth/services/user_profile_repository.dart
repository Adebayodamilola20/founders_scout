import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_profile.dart';
import '../../radar/models/scout_lead.dart';
import '../../setup/models/scout_setup_request.dart';

class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  String? get currentUid => _auth.currentUser?.uid;

  Stream<AppUserProfile?> watchCurrentUserProfile() {
    final uid = currentUid;
    if (uid == null) {
      return const Stream<AppUserProfile?>.empty();
    }
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return AppUserProfile.fromFirestore(snapshot.id, data);
    });
  }

  Future<AppUserProfile?> fetchCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) {
      return null;
    }
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUserProfile.fromFirestore(snapshot.id, data);
  }

  Future<void> createOrMergeUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String homeCity,
  }) async {
    final existing = await _users.doc(uid).get();
    final existingData = existing.data();
    final profile = AppUserProfile(
      uid: uid,
      email: email,
      fullName: fullName.isEmpty ? (existingData?['fullName'] as String? ?? '') : fullName,
      homeCity: homeCity.isEmpty ? (existingData?['homeCity'] as String? ?? '') : homeCity,
      selectedCountry: existingData?['selectedCountry'] as String? ?? 'Nigeria',
      selectedLocation: existingData?['selectedLocation'] as String? ?? homeCity,
      selectedCategories: ((existingData?['selectedCategories'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      selectedDigitalGaps: ((existingData?['selectedDigitalGaps'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      contactedCount: ((existingData?['stats'] as Map<String, dynamic>?)?['contactedCount'] as num?)?.toInt() ?? 0,
      repliedCount: ((existingData?['stats'] as Map<String, dynamic>?)?['repliedCount'] as num?)?.toInt() ?? 0,
      closedCount: ((existingData?['stats'] as Map<String, dynamic>?)?['closedCount'] as num?)?.toInt() ?? 0,
      joinedAt: existingData?['joinedAt'] is Timestamp ? (existingData?['joinedAt'] as Timestamp).toDate() : null,
      updatedAt: null,
    );
    await _users.doc(uid).set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updatePreferences(ScoutSetupRequest request) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).set({
      'selectedCountry': request.country,
      'selectedLocation': request.location,
      'selectedCategories': request.categories,
      'selectedDigitalGaps': request.digitalGaps,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfileFields({
    required String fullName,
    required String email,
    required String homeCity,
    required String selectedCountry,
    required String selectedLocation,
    required List<String> selectedCategories,
    required List<String> selectedDigitalGaps,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'homeCity': homeCity,
      'selectedCountry': selectedCountry,
      'selectedLocation': selectedLocation,
      'selectedCategories': selectedCategories,
      'selectedDigitalGaps': selectedDigitalGaps,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordOutreach({
    required ScoutLead lead,
    required String channel,
    String? stage,
    bool? replied,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    final entry = {
      'leadId': lead.placeId,
      'leadName': lead.name,
      'category': lead.selectedCategory,
      'location': lead.address,
      'channel': channel,
      'stage': stage,
      'replied': replied,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _users.doc(uid).collection('outreachHistory').add(entry);
  }

  Future<void> incrementStat(String field) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).set({
      'stats': {field: FieldValue.increment(1)},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveLead(ScoutLead lead) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).collection('savedLeads').doc(lead.placeId).set({
      'placeId': lead.placeId,
      'name': lead.name,
      'address': lead.address,
      'selectedCategory': lead.selectedCategory,
      'matchedGaps': lead.matchedGaps.toList(),
      'rating': lead.rating,
      'userRatingsTotal': lead.userRatingsTotal,
      'website': lead.website,
      'phoneNumber': lead.phoneNumber,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> loadAllPitchThreads() async {
    final uid = currentUid;
    if (uid == null) {
      return const [];
    }
    try {
      final snapshot = await _users
          .doc(uid)
          .collection('pitchThreads')
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final messages = (data['messages'] as List<dynamic>? ?? const []) as List<dynamic>;
        final lastMessage = messages.isNotEmpty
            ? (messages.last as Map<String, dynamic>)['content'] as String? ?? ''
            : '';
        return {
          'id': doc.id,
          'title': data['title'] as String? ?? 'Untitled',
          'lastMessage': lastMessage,
          'messageCount': messages.length,
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      if (e.toString().contains('unavailable') || e.toString().contains('Unavailable')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> deletePitchThread(String threadId) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).collection('pitchThreads').doc(threadId).delete();
  }

  Future<List<Map<String, String>>> loadPitchConversation(String threadId) async {
    final uid = currentUid;
    if (uid == null) {
      return const [];
    }
    try {
      final snapshot = await _users.doc(uid).collection('pitchThreads').doc(threadId).get();
      final data = snapshot.data();
      final messages = (data?['messages'] as List<dynamic>? ?? const []);
      return messages
          .map((item) => item as Map<String, dynamic>)
          .map((item) => {
                'role': item['role'] as String? ?? 'assistant',
                'content': item['content'] as String? ?? '',
              })
          .where((item) => item['content']!.trim().isNotEmpty)
          .toList();
    } catch (e) {
      if (e.toString().contains('unavailable') || e.toString().contains('Unavailable')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> savePitchConversation({
    required String threadId,
    required String title,
    required List<Map<String, String>> messages,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    await _users.doc(uid).collection('pitchThreads').doc(threadId).set({
      'title': title,
      'messages': messages
          .map((item) => {
                'role': item['role'],
                'content': item['content'],
              })
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
