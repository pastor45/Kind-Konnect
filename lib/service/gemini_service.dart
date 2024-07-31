import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/volunteer_opportunity.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  Future<String> getChatbotResponse(
      String userInput,
      List<VolunteerOpportunity> opportunities,
      String userId,
      List<String> conversationHistory) async {
    final prompt =
        _buildPrompt(userInput, opportunities, userId, conversationHistory);

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? "Sorry, I could not generate a response.";
  }

  String _buildPrompt(
      String userInput,
      List<VolunteerOpportunity> opportunities,
      String userId,
      List<String> conversationHistory) {
    final opportunitiesInfo = opportunities
        .map((o) =>
            "Title: ${o.title}, Category: ${o.category}, description: ${o.description}, Organization: ${o.organization}, Date: ${o.date}, Location: ${o.city}, Volunteer limit: ${o.limit}, Status: ${o.status}")
        .join("\n");
    final history = conversationHistory.join("\n");

    return """
    You are an assistant for an application for volunteer opportunities. 
    Here are the available opportunities:

    $opportunitiesInfo

    The user with ID $userId has said: "$userInput"


    Conversation history:
    $history

    The user with ID $userId has just said: "$userInput"

    Please respond to the user's query based on the opportunities available and the conversation history. 
    If this is not the first interaction, avoid repeating greetings or introducing yourself again.
    Please respond to the user's query based on the opportunities available. 
    If the user asks for recommendations, suggest relevant opportunities. 
    If the user asks a question about a specific opportunity, provide the relevant information.
    If the user wants to register for an opportunity, check if there is space available and if the user is already registered.
    If the user wants to search for opportunities, help them filter by category, date, location or any other relevant criteria.
    Format your response as follows:
    1. Respond directly to the user's question or request.
    2. If you recommend opportunities, list each one in a new paragraph with a relevant emoji at the beginning.
    3. End with a question or suggestion to keep the conversation going.
    4. Use emojis occasionally to make the response more visually appealing.
    5. Maintain a friendly and enthusiastic tone.
    """;
  }
}
