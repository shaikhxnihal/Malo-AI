import 'package:flutter/material.dart';
import 'package:malo/utils/app_theme.dart';

// ── Tier enum ─────────────────────────────────────────────────────
enum ModelTier { ultraLight, light, balanced, highQuality, powerful }

extension ModelTierX on ModelTier {
  String get label {
    switch (this) {
      case ModelTier.ultraLight:  return '🟢  Tier 1 — Ultra Light';
      case ModelTier.light:       return '🔵  Tier 2 — Light';
      case ModelTier.balanced:    return '🟡  Tier 3 — Balanced';
      case ModelTier.highQuality: return '🟠  Tier 4 — High Quality';
      case ModelTier.powerful:    return '🔴  Tier 5 — Powerful';
    }
  }

  String get subtitle {
    switch (this) {
      case ModelTier.ultraLight:  return '1–2 GB RAM · Budget & old phones';
      case ModelTier.light:       return '2–3 GB RAM · Mid-range phones';
      case ModelTier.balanced:    return '4–5 GB RAM · Flagship phones';
      case ModelTier.highQuality: return '6–8 GB RAM · High-end phones';
      case ModelTier.powerful:    return '10–24 GB RAM · Tablets & laptops';
    }
  }

  Color get color {
    switch (this) {
      case ModelTier.ultraLight:  return AppColors.success;
      case ModelTier.light:       return AppColors.blue;
      case ModelTier.balanced:    return AppColors.accent;
      case ModelTier.highQuality: return AppColors.warn;
      case ModelTier.powerful:    return AppColors.danger;
    }
  }
}

// ── LlmModel ──────────────────────────────────────────────────────
class LlmModel {
  final String id;
  final String name;
  final String version;
  final String family;
  final String size;
  final int sizeMB; // ✅ FIXED: Renamed from sizeBytes to sizeMB
  final String ram;
  final int ramGB;
  final int quality; // 1-5
  final String tag;
  final Color tagColor;
  final String description;
  final String quant;
  final String tokensPerSec;
  final int minRamGB;
  final int minStorageMB;
  final bool recommended;
  final String downloadUrl;
  final ModelTier tier;

  const LlmModel({
    required this.id,
    required this.name,
    required this.version,
    required this.family,
    required this.size,
    required this.sizeMB, // ✅ FIXED
    required this.ram,
    required this.ramGB,
    required this.quality,
    required this.tag,
    required this.tagColor,
    required this.description,
    required this.quant,
    required this.tokensPerSec,
    required this.minRamGB,
    required this.minStorageMB,
    required this.recommended,
    required this.downloadUrl,
    required this.tier,
  });
}

// ── Chat entities ──────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String role;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.id, required this.role, required this.text, required this.timestamp});

  Map<String, dynamic> toMap() => {
        'id': id, 'role': role, 'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'], role: map['role'], text: map['text'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      );
}

class ChatSession {
  final String id;
  String title;
  final String modelId;
  final String modelName;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessage> messages; // ✅ FIXED: Removed 'const' to allow mutation
  int messageCount;

  ChatSession({
    required this.id, required this.title, required this.modelId,
    required this.modelName, required this.createdAt, required this.updatedAt,
    List<ChatMessage>? messages, // ✅ FIXED: Allow null, default to empty mutable list
    this.messageCount = 0,
  }) : messages = messages ?? []; // ✅ FIXED: Mutable list

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'modelId': modelId, 'modelName': modelName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'messageCount': messageCount,
      };

  factory ChatSession.fromMap(Map<String, dynamic> map) => ChatSession(
        id: map['id'], title: map['title'], modelId: map['modelId'],
        modelName: map['modelName'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
        messageCount: map['messageCount'] ?? 0,
      );
}

class DeviceInfo {
  final int ramGB;
  final int availableStorageMB;
  final String deviceName;
  const DeviceInfo({required this.ramGB, required this.availableStorageMB, required this.deviceName});
}

// ── DownloadState (shared singleton state) ─────────────────────────
class DownloadState {
  final String modelId;
  final double progress;
  final double speedMbs;
  final int receivedMB;
  final int totalMB;
  final bool isComplete;
  final bool hasError;
  final String? errorMsg;
  final String phase;

  const DownloadState({
    required this.modelId,
    this.progress = 0,
    this.speedMbs = 0,
    this.receivedMB = 0,
    this.totalMB = 0,
    this.isComplete = false,
    this.hasError = false,
    this.errorMsg,
    this.phase = 'Connecting...',
  });

  DownloadState copyWith({
    double? progress, double? speedMbs, int? receivedMB, int? totalMB,
    bool? isComplete, bool? hasError, String? errorMsg, String? phase,
  }) => DownloadState(
    modelId: modelId,
    progress: progress ?? this.progress,
    speedMbs: speedMbs ?? this.speedMbs,
    receivedMB: receivedMB ?? this.receivedMB,
    totalMB: totalMB ?? this.totalMB,
    isComplete: isComplete ?? this.isComplete,
    hasError: hasError ?? this.hasError,
    errorMsg: errorMsg ?? this.errorMsg,
    phase: phase ?? this.phase,
  );
}

// ── Model catalogue ────────────────────────────────────────────────
final List<LlmModel> kAvailableModels = [

  // ═══ TIER 1 — Ultra Light ══════════════════════════════════════

  LlmModel(
    id: 'SmolLM2-1.7B',
    name: 'SmolLM2', version: '1.7B', family: 'HuggingFace',
    size: '1.0 GB', sizeMB: 1000, // ✅ FIXED
    ram: '2 GB', ramGB: 2, quality: 2,
    tag: 'Ultra Light', tagColor: AppColors.success,
    description: 'Best-in-class small model. Excellent instruction following for its size.',
    quant: 'Q4_K_M', tokensPerSec: '~22 tok/s',
    minRamGB: 2, minStorageMB: 1200, recommended: false,
    downloadUrl: 'https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf',
    tier: ModelTier.ultraLight,
  ),
  LlmModel(
    id: 'google_gemma-3-1b-it',
    name: 'Gemma 3', version: '1B', family: 'Google',
    size: '800 MB', sizeMB: 800, // ✅ FIXED
    ram: '2 GB', ramGB: 2, quality: 2,
    tag: 'Ultra Light', tagColor: AppColors.success,
    description: "Google's smallest Gemma. 128K context. Strong for its tiny size.",
    quant: 'Q4_K_M', tokensPerSec: '~25 tok/s',
    minRamGB: 2, minStorageMB: 1000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf',
    tier: ModelTier.ultraLight,
  ),
  LlmModel(
    id: 'Qwen3-0.6B',
    name: 'Qwen3', version: '0.6B', family: 'Alibaba',
    size: '400 MB', sizeMB: 400, // ✅ FIXED
    ram: '1.5 GB', ramGB: 2, quality: 1,
    tag: 'Ultra Light', tagColor: AppColors.success,
    description: "Alibaba's tiny powerhouse. Thinking mode support even at this size.",
    quant: 'Q8_0', tokensPerSec: '~28 tok/s',
    minRamGB: 2, minStorageMB: 600, recommended: false,
    downloadUrl: 'https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
    tier: ModelTier.ultraLight,
  ),

  // ═══ TIER 2 — Light ════════════════════════════════════════════
  LlmModel(
    id: 'Llama-3.2-3B-Instruct',
    name: 'Llama 3.2', version: '3B', family: 'Meta',
    size: '1.9 GB', sizeMB: 1900, // ✅ FIXED
    ram: '3 GB', ramGB: 3, quality: 3,
    tag: 'Light', tagColor: AppColors.blue,
    description: "Meta's edge-optimized model. Built for ARM/Qualcomm mobile CPUs.",
    quant: 'Q4_K_M', tokensPerSec: '~15 tok/s',
    minRamGB: 3, minStorageMB: 2500, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    tier: ModelTier.light,
  ),
  LlmModel(
    id: 'Qwen3-1.7B',
    name: 'Qwen3', version: '1.7B', family: 'Alibaba',
    size: '1.1 GB', sizeMB: 1100, // ✅ FIXED
    ram: '2 GB', ramGB: 2, quality: 2,
    tag: 'Light', tagColor: AppColors.blue,
    description: 'Hybrid thinking/non-thinking mode. Great multilingual support.',
    quant: 'Q4_K_M', tokensPerSec: '~20 tok/s',
    minRamGB: 2, minStorageMB: 1500, recommended: false,
    downloadUrl: 'https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf',
    tier: ModelTier.light,
  ),
  LlmModel(
    id: 'Qwen3.5-2B',
    name: 'Qwen3.5', version: '2B', family: 'Alibaba',
    size: '1.4 GB', sizeMB: 1400, // ✅ FIXED
    ram: '2 GB', ramGB: 2, quality: 3,
    tag: 'Light', tagColor: AppColors.blue,
    description: 'Latest Qwen3.5 series. Improved reasoning and coding over Qwen3.',
    quant: 'Q4_K_M', tokensPerSec: '~18 tok/s',
    minRamGB: 2, minStorageMB: 2000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3.5-2B-GGUF/resolve/main/Qwen_Qwen3.5-2B-Q4_K_M.gguf',
    tier: ModelTier.light,
  ),
  LlmModel(
    id: 'DeepSeek-R1-Distill-Qwen-1.5B',
    name: 'DeepSeek R1', version: '1.5B', family: 'DeepSeek',
    size: '1.0 GB', sizeMB: 1000, // ✅ FIXED
    ram: '2 GB', ramGB: 2, quality: 2,
    tag: 'Reasoning', tagColor: AppColors.purple,
    description: 'DeepSeek R1 reasoning distilled to 1.5B. Chain-of-thought built in.',
    quant: 'Q4_K_M', tokensPerSec: '~20 tok/s',
    minRamGB: 2, minStorageMB: 1500, recommended: false,
    downloadUrl: 'https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
    tier: ModelTier.light,
  ),
  LlmModel(
    id: 'google_gemma-3-4b-it',
    name: 'Gemma 3', version: '4B', family: 'Google',
    size: '2.5 GB', sizeMB: 2500, // ✅ FIXED
    ram: '3 GB', ramGB: 3, quality: 3,
    tag: 'Light', tagColor: AppColors.blue,
    description: "Google's 4B multimodal model. 128K context. Strong general chat.",
    quant: 'Q4_K_M', tokensPerSec: '~12 tok/s',
    minRamGB: 3, minStorageMB: 3200, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/google_gemma-3-4b-it-GGUF/resolve/main/google_gemma-3-4b-it-Q4_K_M.gguf',
    tier: ModelTier.light,
  ),

  // ═══ TIER 3 — Balanced ═════════════════════════════════════════
  LlmModel(
    id: 'microsoft_Phi-4-mini-instruct',
    name: 'Phi-4 Mini', version: '3.8B', family: 'Microsoft',
    size: '2.2 GB', sizeMB: 2200, // ✅ FIXED
    ram: '4 GB', ramGB: 4, quality: 4,
    tag: 'Recommended', tagColor: AppColors.accent,
    description: "Microsoft's compact powerhouse. Top reasoning and coding performance.",
    quant: 'Q4_K_M', tokensPerSec: '~10 tok/s',
    minRamGB: 4, minStorageMB: 3000, recommended: true,
    downloadUrl: 'https://huggingface.co/bartowski/microsoft_Phi-4-mini-instruct-GGUF/resolve/main/microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
    tier: ModelTier.balanced,
  ),
  LlmModel(
    id: 'microsoft_Phi-4-mini-reasoning',
    name: 'Phi-4 Mini', version: '3.8B Reasoning', family: 'Microsoft',
    size: '2.2 GB', sizeMB: 2200, // ✅ FIXED
    ram: '4 GB', ramGB: 4, quality: 4,
    tag: 'Reasoning', tagColor: AppColors.purple,
    description: 'Phi-4 Mini fine-tuned for math & reasoning. Thinking traces included.',
    quant: 'Q4_K_M', tokensPerSec: '~9 tok/s',
    minRamGB: 4, minStorageMB: 3000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/microsoft_Phi-4-mini-reasoning-GGUF/resolve/main/microsoft_Phi-4-mini-reasoning-Q4_K_M.gguf',
    tier: ModelTier.balanced,
  ),
  LlmModel(
    id: 'Qwen3-4B',
    name: 'Qwen3', version: '4B', family: 'Alibaba',
    size: '2.6 GB', sizeMB: 2600, // ✅ FIXED
    ram: '4 GB', ramGB: 4, quality: 4,
    tag: 'Balanced', tagColor: AppColors.accent,
    description: 'Rivals Qwen2.5-72B on reasoning benchmarks. Incredible 4B model.',
    quant: 'Q4_K_M', tokensPerSec: '~10 tok/s',
    minRamGB: 4, minStorageMB: 3500, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3-4B-GGUF/resolve/main/Qwen_Qwen3-4B-Q4_K_M.gguf',
    tier: ModelTier.balanced,
  ),
  LlmModel(
    id: 'Qwen3.5-4B',
    name: 'Qwen3.5', version: '4B', family: 'Alibaba',
    size: '2.6 GB', sizeMB: 2600, // ✅ FIXED
    ram: '4 GB', ramGB: 4, quality: 4,
    tag: 'Balanced', tagColor: AppColors.accent,
    description: 'Latest Qwen3.5. Better instruction following & coding than Qwen3-4B.',
    quant: 'Q4_K_M', tokensPerSec: '~10 tok/s',
    minRamGB: 4, minStorageMB: 3500, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3.5-4B-GGUF/resolve/main/Qwen_Qwen3.5-4B-Q4_K_M.gguf',
    tier: ModelTier.balanced,
  ),

  // ═══ TIER 4 — High Quality ═════════════════════════════════════
  LlmModel(
    id: 'Qwen3-8B',
    name: 'Qwen3', version: '8B', family: 'Alibaba',
    size: '5.0 GB', sizeMB: 5000, // ✅ FIXED
    ram: '6 GB', ramGB: 6, quality: 5,
    tag: 'High Quality', tagColor: AppColors.warn,
    description: 'Thinking + non-thinking modes. Near-desktop quality on flagship phones.',
    quant: 'Q4_K_M', tokensPerSec: '~8 tok/s',
    minRamGB: 6, minStorageMB: 6000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3-8B-GGUF/resolve/main/Qwen_Qwen3-8B-Q4_K_M.gguf',
    tier: ModelTier.highQuality,
  ),
  LlmModel(
    id: 'Qwen3.5-9B',
    name: 'Qwen3.5', version: '9B', family: 'Alibaba',
    size: '5.5 GB', sizeMB: 5500, // ✅ FIXED
    ram: '7 GB', ramGB: 7, quality: 5,
    tag: 'High Quality', tagColor: AppColors.warn,
    description: 'Latest Qwen3.5 9B. Best overall quality in the high-quality tier.',
    quant: 'Q4_K_M', tokensPerSec: '~7 tok/s',
    minRamGB: 7, minStorageMB: 7000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3.5-9B-GGUF/resolve/main/Qwen_Qwen3.5-9B-Q4_K_M.gguf',
    tier: ModelTier.highQuality,
  ),
  LlmModel(
    id: 'DeepSeek-R1-Distill-Qwen-7B',
    name: 'DeepSeek R1', version: '7B', family: 'DeepSeek',
    size: '4.4 GB', sizeMB: 4400, // ✅ FIXED
    ram: '6 GB', ramGB: 6, quality: 5,
    tag: 'Reasoning', tagColor: AppColors.purple,
    description: 'R1 reasoning distilled into 7B. Excellent math, code, and logic.',
    quant: 'Q4_K_M', tokensPerSec: '~6 tok/s',
    minRamGB: 6, minStorageMB: 5500, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf',
    tier: ModelTier.highQuality,
  ),
  LlmModel(
    id: 'DeepSeek-R1-Distill-Llama-8B',
    name: 'DeepSeek R1', version: '8B Llama', family: 'DeepSeek',
    size: '5.0 GB', sizeMB: 5000, // ✅ FIXED
    ram: '7 GB', ramGB: 7, quality: 5,
    tag: 'Reasoning', tagColor: AppColors.purple,
    description: 'R1 reasoning on Llama 8B base. Slightly better general knowledge.',
    quant: 'Q4_K_M', tokensPerSec: '~6 tok/s',
    minRamGB: 7, minStorageMB: 6000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf',
    tier: ModelTier.highQuality,
  ),
  LlmModel(
    id: 'google_gemma-3-12b-it',
    name: 'Gemma 3', version: '12B', family: 'Google',
    size: '7.0 GB', sizeMB: 7000, // ✅ FIXED
    ram: '8 GB', ramGB: 8, quality: 5,
    tag: 'High Quality', tagColor: AppColors.warn,
    description: "Google's 12B model. 128K context. Great for complex conversations.",
    quant: 'Q4_K_M', tokensPerSec: '~5 tok/s',
    minRamGB: 8, minStorageMB: 8500, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/google_gemma-3-12b-it-GGUF/resolve/main/google_gemma-3-12b-it-Q4_K_M.gguf',
    tier: ModelTier.highQuality,
  ),

  // ═══ TIER 5 — Powerful ═════════════════════════════════════════
  LlmModel(
    id: 'Qwen3-14B',
    name: 'Qwen3', version: '14B', family: 'Alibaba',
    size: '9.0 GB', sizeMB: 9000, // ✅ FIXED
    ram: '12 GB', ramGB: 12, quality: 5,
    tag: 'Powerful', tagColor: AppColors.danger,
    description: 'Near-frontier quality. Tablets & laptops only. Exceptional reasoning.',
    quant: 'Q4_K_M', tokensPerSec: '~4 tok/s',
    minRamGB: 12, minStorageMB: 11000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3-14B-GGUF/resolve/main/Qwen_Qwen3-14B-Q4_K_M.gguf',
    tier: ModelTier.powerful,
  ),
  LlmModel(
    id: 'DeepSeek-R1-Distill-Qwen-14B',
    name: 'DeepSeek R1', version: '14B', family: 'DeepSeek',
    size: '9.0 GB', sizeMB: 9000, // ✅ FIXED
    ram: '12 GB', ramGB: 12, quality: 5,
    tag: 'Powerful', tagColor: AppColors.danger,
    description: 'Full R1 reasoning in 14B. Best reasoning model for high-end devices.',
    quant: 'Q4_K_M', tokensPerSec: '~3 tok/s',
    minRamGB: 12, minStorageMB: 11000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf',
    tier: ModelTier.powerful,
  ),
  LlmModel(
    id: 'google_gemma-3-27b-it',
    name: 'Gemma 3', version: '27B', family: 'Google',
    size: '16.0 GB', sizeMB: 16000, // ✅ FIXED
    ram: '18 GB', ramGB: 18, quality: 5,
    tag: 'Powerful', tagColor: AppColors.danger,
    description: "Google's flagship open model. Desktop/server only. Outstanding quality.",
    quant: 'Q4_K_M', tokensPerSec: '~2 tok/s',
    minRamGB: 18, minStorageMB: 18000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/google_gemma-3-27b-it-GGUF/resolve/main/google_gemma-3-27b-it-Q4_K_M.gguf',
    tier: ModelTier.powerful,
  ),
  LlmModel(
    id: 'Qwen3-32B',
    name: 'Qwen3', version: '32B', family: 'Alibaba',
    size: '20.0 GB', sizeMB: 20000, // ✅ FIXED
    ram: '24 GB', ramGB: 24, quality: 5,
    tag: 'Powerful', tagColor: AppColors.danger,
    description: 'Server-class intelligence. Requires high-end workstation.',
    quant: 'Q4_K_M', tokensPerSec: '~1 tok/s',
    minRamGB: 24, minStorageMB: 24000, recommended: false,
    downloadUrl: 'https://huggingface.co/bartowski/Qwen_Qwen3-32B-GGUF/resolve/main/Qwen_Qwen3-32B-Q4_K_M.gguf',
    tier: ModelTier.powerful,
  ),
];

/// Models grouped by tier
Map<ModelTier, List<LlmModel>> get kModelsByTier {
  final map = <ModelTier, List<LlmModel>>{};
  for (final tier in ModelTier.values) {
    map[tier] = kAvailableModels.where((m) => m.tier == tier).toList();
  }
  return map;
}
