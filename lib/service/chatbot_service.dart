import 'dart:async';
import 'firestore_service.dart';
import 'gemini_service.dart';
import '../models/volunteer_opportunity.dart';
import '../models/user_profile.dart';

class ChatbotService {
  final FirestoreService _firestoreService;
  final GeminiService _geminiService;
  final Map<String, List<String>> _conversationHistory = {};

  ChatbotService(this._firestoreService, this._geminiService);

  Future<String> getResponse(String userInput, String userId) async {
    if (!_conversationHistory.containsKey(userId)) {
      _conversationHistory[userId] = [];
    }

    _conversationHistory[userId]!.add("User: $userInput");

    final UserProfile? userProfile =
        await _firestoreService.getUserProfile(userId);
    final List<VolunteerOpportunity> allOpportunities =
        await _firestoreService.getOpportunities().first;
    List<VolunteerOpportunity> relevantOpportunities =
        _filterOpportunities(userProfile, allOpportunities);

    final response = await _geminiService.getChatbotResponse(
        userInput,
        relevantOpportunities,
        userId,
        _conversationHistory[userId]! 
        );

    _conversationHistory[userId]!.add("Chatbot: $response");
    if (_conversationHistory[userId]!.length > 10) {
      _conversationHistory[userId] = _conversationHistory[userId]!
          .sublist(_conversationHistory[userId]!.length - 10);
    }

    if (response.contains("register")) {
      final opportunityId = _extractOpportunityId(response);
      await _firestoreService.registerVolunteer(opportunityId, userId);
      return "I have registered you for the opportunity. $response";
    }

    return response;
  }

  List<VolunteerOpportunity> _filterOpportunities(
      UserProfile? userProfile, List<VolunteerOpportunity> allOpportunities) {
    if (userProfile != null &&
        userProfile.interests != null &&
        userProfile.interests!.isNotEmpty) {
      var filtered = allOpportunities.where((opportunity) {
        return userProfile.interests!.contains(opportunity.category);
      }).toList();
      return filtered.isNotEmpty ? filtered : allOpportunities;
    }
    return allOpportunities;
  }

  String _extractOpportunityId(String response) {
    final match = RegExp(r'ID: (\w+)').firstMatch(response);
    return match?.group(1) ?? '';
  }
}
