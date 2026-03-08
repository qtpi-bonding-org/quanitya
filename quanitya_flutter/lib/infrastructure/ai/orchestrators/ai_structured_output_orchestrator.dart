import '../../llm/models/llm_types.dart';
import '../../llm/services/llm_service.dart';

/// Abstract orchestrator class that manages the entire AI structured output pipeline.
///
/// This orchestrator coordinates:
/// 1. JSON schema generation
/// 2. System/user prompt building
/// 3. LLM API calls with structured output
/// 4. JSON response parsing to domain models
/// 5. Error handling and validation
///
/// Type Parameters:
/// - TInput: The input type for the AI generation (e.g., TemplateInput, AnalysisInput)
/// - TOutput: The output type after parsing (e.g., ParsedAiTemplate, PipelineSuggestion)
abstract class AiStructuredOutputOrchestrator<TInput, TOutput> {
  final LlmService _llmService;
  
  AiStructuredOutputOrchestrator(this._llmService);
  
  /// Main orchestration method that coordinates the entire AI generation pipeline.
  ///
  /// This method:
  /// 1. Generates the JSON schema for structured output
  /// 2. Builds system and user prompts
  /// 3. Calls the LLM service with structured output constraints
  /// 4. Parses the JSON response into the target domain model
  ///
  /// Throws exceptions if any step fails - callers should wrap in tryMethod/tryOperation.
  Future<TOutput> generate(TInput input, LlmConfig config) async {
    // 1. Generate JSON schema for structured output
    final schema = generateSchema(input);
    
    // 2. Build prompts based on input
    final systemPrompt = buildSystemPrompt(input);
    final userPrompt = buildUserPrompt(input);
    
    // 3. Call LLM with structured output constraints
    final response = await _llmService.execute(config, LlmRequest(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonSchema: schema,
      callType: callType,
    ));
    
    // 4. Parse JSON response to domain models
    return parseResponse(response.data, input);
  }
  
  /// The call type for server-side model routing (cloud proxy).
  /// Subclasses must specify whether this is a template or analysis call.
  LlmCallType get callType;

  /// Generate the JSON schema that constrains the LLM's structured output.
  ///
  /// This schema defines the exact structure the LLM must follow when generating
  /// its response. It should include all required fields, types, and constraints.
  ///
  /// The schema must have `"additionalProperties": false` for strict mode compliance.
  Map<String, dynamic> generateSchema(TInput input);
  
  /// Build the system prompt that defines the AI's role and behavior.
  ///
  /// The system prompt should:
  /// - Define the AI's expertise and role
  /// - Explain the task and context
  /// - Provide guidelines and constraints
  /// - Reference the JSON schema requirements
  String buildSystemPrompt(TInput input);
  
  /// Build the user prompt from the input data.
  ///
  /// This typically extracts the user's natural language request from the input
  /// and formats it appropriately for the LLM.
  String buildUserPrompt(TInput input);
  
  /// Parse the LLM's JSON response into the target domain model.
  ///
  /// This method should:
  /// - Validate the JSON structure
  /// - Transform the raw JSON into typed domain objects
  /// - Handle any post-processing or validation
  /// - Throw meaningful exceptions for invalid responses
  TOutput parseResponse(Map<String, dynamic> json, TInput input);
}