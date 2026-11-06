import 'dart:convert';

class ValidationRule {
  final int id;
  final int version;
  final String description;
  final String? errorMessage;
  final List<String> entityTypeNames;
  final List<String> changedFieldNames;
  final bool runOnCreate;
  final bool runOnUpdate;
  final bool runOnDelete;
  final String dslCondition;
  final int createdByUserId;
  final bool isEnabled;

  ValidationRule({
    required this.id,
    required this.version,
    required this.description,
    this.errorMessage,
    required this.entityTypeNames,
    required this.changedFieldNames,
    required this.runOnCreate,
    required this.runOnUpdate,
    required this.runOnDelete,
    required this.dslCondition,
    required this.createdByUserId,
    required this.isEnabled,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      id: json['id'] as int,
      version: json['version'] as int,
      description: json['description'] as String,
      errorMessage: json['errorMessage'] as String?,
      entityTypeNames: List<String>.from(json['entityTypeNames'] as List),
      changedFieldNames: List<String>.from(json['changedFieldNames'] as List),
      runOnCreate: json['runOnCreate'] as bool,
      runOnUpdate: json['runOnUpdate'] as bool,
      runOnDelete: json['runOnDelete'] as bool,
      dslCondition: json['dslCondition'] as String,
      createdByUserId: json['createdByUserId'] as int,
      isEnabled: json['isEnabled'] as bool,
    );
  }
}

class ValidationRulesService {
  static Future<List<ValidationRule>> loadValidationRulesFromBytes(
      List<int> bytes) async {
    try {
      final String jsonString = utf8.decode(bytes);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> itemsList = jsonData['items'] as List<dynamic>;

      return itemsList
          .map((item) => ValidationRule.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error loading validation rules: $e');
    }
  }

  static List<String> getAllEntityTypes(List<ValidationRule> rules) {
    final Set<String> entityTypes = {};
    for (var rule in rules) {
      entityTypes.addAll(rule.entityTypeNames);
    }
    return entityTypes.toList()..sort();
  }
}
