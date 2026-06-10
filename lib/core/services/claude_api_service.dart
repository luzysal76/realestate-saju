// claude_api_service.dart — Anthropic Claude API 연동
// AI 동네 리포트: 사주 정보 → 맞춤 텍스트 생성
import 'dart:convert';
import 'package:http/http.dart' as http;

// ▼ Anthropic Console에서 발급: https://console.anthropic.com/settings/keys
const _claudeApiKey = '';

bool get claudeApiConfigured => _claudeApiKey.isNotEmpty;

class ClaudeApiService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5';
  static const _maxTokens = 600;

  /// 자치구 AI 리포트 생성
  static Future<String> generateDistrictReport({
    required String districtName,
    required String districtDesc,
    required String mainOe,
    required String weakOe,
    required String name,
    required int sajuScore,
    required int transitScore,
    required int amenityScore,
    String? commuteDistrict,
    int? budgetAk,
    int? childrenCount,
    bool hasPet = false,
  }) async {
    if (!claudeApiConfigured) {
      return '⚠️ Claude API 키가 설정되지 않았습니다.\nclaude_api_service.dart의 _claudeApiKey에 발급받은 키를 입력해주세요.\nhttps://console.anthropic.com/settings/keys';
    }

    final lifestyleDesc = _buildLifestyleDesc(
        commuteDistrict, budgetAk, childrenCount, hasPet);

    final prompt = '''
당신은 사주명리학과 부동산을 결합한 주거 전문 AI입니다.
아래 정보를 바탕으로 "$name"님에게 "$districtName"을 추천하는 이유를 한국어로 3~4문장으로 작성해주세요.

[사용자 정보]
- 이름: $name
- 주 오행: $mainOe(${_oeHanja(mainOe)}) / 보완 오행: $weakOe
- 생활조건: $lifestyleDesc

[지역 정보]
- 자치구: $districtName
- 지역 특성: $districtDesc
- 사주 적합도: $sajuScore/100
- 교통 편의성: $transitScore/100
- 생활 편의시설: $amenityScore/100

작성 기준:
- 사주 오행과 지역 기운의 연결을 구체적으로 설명
- 생활조건과 지역 특성의 연관성 포함
- 긍정적이고 설득력 있는 톤
- 이모지 1~2개 자연스럽게 포함
- 300자 이내
''';

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'x-api-key': _claudeApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': _maxTokens,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = (data['content'] as List?)?.first;
        return (content?['text'] as String?) ?? '리포트를 생성할 수 없습니다.';
      } else if (res.statusCode == 401) {
        return '❌ API 키가 올바르지 않습니다. 키를 확인해주세요.';
      } else {
        return '❌ 오류 발생 (${res.statusCode}). 잠시 후 다시 시도해주세요.';
      }
    } catch (e) {
      return '❌ 네트워크 오류: $e';
    }
  }

  static String _buildLifestyleDesc(String? commute, int? budget,
      int? children, bool hasPet) {
    final parts = <String>[];
    if (commute != null && commute != '재택/없음') parts.add('출근지: $commute');
    if (budget != null && budget > 0) parts.add('예산: ${budget}억 이내');
    if (children != null && children > 0) parts.add('자녀 ${children}명');
    if (hasPet) parts.add('반려동물 있음');
    return parts.isEmpty ? '미설정' : parts.join(', ');
  }

  /// 건물 궁합 AI 심층 분석
  static Future<String> generateBuildingAnalysis({
    required String name,
    required String ilgan,
    required String ilji,
    required String mainOe,
    required String bldGanJi,
    required String sipseong,
    required String cgRel,
    required String jiRel,
    required int score,
    required String compatType,
    required String address,
  }) async {
    if (!claudeApiConfigured) {
      return '⚠️ Claude API 키 미설정\nclaude_api_service.dart의 _claudeApiKey를 입력해주세요.\nhttps://console.anthropic.com/settings/keys';
    }
    final prompt = '''
당신은 사주명리학 전문가이자 부동산 컨설턴트입니다.
"$name"님과 해당 건물의 궁합을 심층 분석해 주세요.

[사용자 사주]
- 일간: $ilgan (${_oeHanja(mainOe)} 오행) / 일지: $ilji

[건물 정보]
- 주소: ${address.isNotEmpty ? address : '미입력'}
- 건물 년주: $bldGanJi
- 궁합 점수: $score/100 ($compatType)
- 천간 관계: $cgRel
- 지지 관계: $jiRel
- 십성: $sipseong

아래 형식으로 분석해 주세요:
1. 종합 평가 (2문장, 사주 기운과 건물 기운의 상호작용 중심)
2. 거주 시 예상 변화 (재물/건강/관계 중 가장 영향 큰 1~2가지)
3. 입주 추천 시기 또는 비보(裨補) 조언 (1문장)

총 250자 이내. 이모지 2~3개. 명리학 용어는 쉽게 설명.
''';
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'x-api-key': _claudeApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 500,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = (data['content'] as List?)?.first;
        return (content?['text'] as String?) ?? '분석을 생성할 수 없습니다.';
      } else if (res.statusCode == 401) {
        return '❌ API 키가 올바르지 않습니다.';
      }
      return '❌ 오류 (${res.statusCode})';
    } catch (e) {
      return '❌ 네트워크 오류: $e';
    }
  }

  static String _oeHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}
