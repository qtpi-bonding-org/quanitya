# LLM Service

Super lightweight LLM service with structured output support and conversational chat, compatible with OpenRouter and Ollama.

## Features

- ✅ **Structured Outputs**: Enforces strict JSON schema compliance
- ✅ **Conversational Chat**: Multi-turn conversations and simple Q&A
- ✅ **Provider Agnostic**: Works with OpenRouter (cloud) and Ollama (local)
- ✅ **Type Safe**: Freezed models with compile-time safety
- ✅ **Injectable**: Integrates with Quanitya's dependency injection
- ✅ **UI Flow Integration**: Works with cubit UI flow pattern

## Quick Start

### 1. Structured Output (Template Generation)

```dart
final llmService = getIt<LlmService>();

final config = LlmConfig.ollama(model: 'llama3.2');

final request = LlmRequest(
  systemPrompt: 'You are a template generator...',
  userPrompt: 'Create a mood tracking template',
  jsonSchema: mySchema, // Must have additionalProperties: false
);

final response = await llmService.execute(config, request);
final data = response.data; // Guaranteed to match your schema
```

### 2. Conversational Chat

```dart
final chatService = getIt<LlmChatService>();

// Simple Q&A
final answer = await chatService.ask(
  config: config,
  systemPrompt: 'You are a wellness assistant...',
  question: 'How can I improve my mood tracking?',
);

// Multi-turn conversation
final messages = [
  LlmChatMessage.system('You are a wellness coach...'),
  LlmChatMessage.user('I tracked my mood for a week...'),
  LlmChatMessage.assistant('I notice your mood dipped on Tuesday...'),
  LlmChatMessage.user('How can I handle stress better?'),
];

final response = await chatService.converse(
  config: config,
  messages: messages,
);
```

### 3. Stats Analysis Chat

```dart
final userData = {
  'mood_average': 7.2,
  'mood_trend': 'improving',
  'stress_days': 3,
  'sleep_hours': 7.5,
};

final insights = await chatService.analyzeStats(
  config: config,
  question: 'How is my wellness trending this month?',
  userData: userData,
);
```

### 2. Integration with Cubit UI Flow

```dart
@injectable
class MyCubit extends QuanityaCubit<MyState> {
  final LlmService _llmService;
  
  MyCubit(this._llmService) : super(const MyState());
  
  Future<void> generateContent() async {
    await tryOperation(() async {
      final response = await _llmService.execute(config, request);
      return state.copyWith(
        status: UiFlowStatus.success,
        data: response.data,
      );
    }, emitLoading: true); // Automatic loading overlay
  }
}
```

### 3. UI Integration

```dart
UiFlowStateListener<MyCubit, MyState>(
  mapper: getIt<MyMessageMapper>(),
  child: BlocBuilder<MyCubit, MyState>(
    builder: (context, state) {
      // Automatic loading/error handling!
      return MyWidget(data: state.data);
    },
  ),
)
```

## Schema Requirements

For strict mode compliance, your JSON schema must:

```dart
final schema = {
  "type": "object",
  "properties": {
    "field1": {"type": "string"},
    "field2": {"type": "number"},
  },
  "required": ["field1", "field2"],
  "additionalProperties": false, // ← REQUIRED for strict mode
};
```

## Provider Setup

### OpenRouter
1. Get API key from [openrouter.ai](https://openrouter.ai)
2. Choose a model that supports structured outputs
3. Use `LlmConfig.openRouter()` factory

### Ollama
1. Install Ollama locally
2. Pull a compatible model: `ollama pull llama3.2`
3. Start Ollama server: `ollama serve`
4. Use `LlmConfig.ollama()` factory

## Demo

Run the demos to see both capabilities in action:

### Template Generator Demo
- Navigate to "🤖 LLM Template Generator" from the main screen
- Enter a template description
- Watch the AI generate a structured template
- Try regenerating with modifications

### Chat Demo
- Navigate to "💬 LLM Chat Demo" from the main screen
- Ask questions about wellness and mood tracking
- Try the quick-start buttons for common queries
- Experience multi-turn conversations

## Use Cases

### Structured Output
- Template generation
- Data extraction
- Form creation
- Configuration generation

### Conversational Chat
- User support and guidance
- Data analysis and insights
- Wellness coaching
- FAQ responses
- Stats interpretation

## Error Handling

The service throws `LlmException` for:
- Network errors
- Model incompatibility (doesn't support structured outputs)
- Invalid JSON schema
- API authentication issues

All exceptions integrate with the global exception mapping system for consistent UI feedback.