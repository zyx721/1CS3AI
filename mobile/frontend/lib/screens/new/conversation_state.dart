// lib/models/conversation_state.dart
enum ConversationState {
  connecting,    // Initial state while trying to connect to WebSocket
  idle,          // No one is speaking
  listening,     // User (conceptually) is speaking
  speakingAgent, // AI Agent is speaking
}