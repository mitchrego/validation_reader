import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_w;
import 'package:printing/printing.dart';

void main() {
  runApp(const ValidationReaderApp());
}

// Model for Validation Rule
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

// Service to load and parse validation rules
class ValidationRulesService {
  static Future<List<ValidationRule>> loadValidationRulesFromFile(
      String filePath) async {
    try {
      final File file = File(filePath);
      final String jsonString = await file.readAsString();
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

class ValidationReaderApp extends StatelessWidget {
  const ValidationReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Validation Rule Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ValidationRulesScreen(),
    );
  }
}

class ValidationRulesScreen extends StatefulWidget {
  const ValidationRulesScreen({super.key});

  @override
  State<ValidationRulesScreen> createState() => _ValidationRulesScreenState();
}

class _ValidationRulesScreenState extends State<ValidationRulesScreen> {
  late Future<List<ValidationRule>>? _rulesFuture;
  String? _selectedFilePath;
  String? _selectedEntityType;
  String _searchQuery = '';
  List<ValidationRule> _filteredRules = [];
  List<ValidationRule> _allRules = [];
  List<String> _allEntityTypes = [];

  @override
  void initState() {
    super.initState();
    _rulesFuture = null;
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Validation Rules JSON File',
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _rulesFuture =
              ValidationRulesService.loadValidationRulesFromFile(_selectedFilePath!);
          _selectedEntityType = null;
          _searchQuery = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _applyFilters(List<ValidationRule> allRules) {
    _filteredRules = allRules.where((rule) {
      final matchesEntityType = _selectedEntityType == null ||
          rule.entityTypeNames.contains(_selectedEntityType);
      final matchesSearch = _searchQuery.isEmpty ||
          rule.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rule.id.toString().contains(_searchQuery);
      return matchesEntityType && matchesSearch;
    }).toList();
  }

  Future<void> _showPdfPreview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ValidationRulesPdfPreview(rules: _filteredRules),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Rule Reader'),
        elevation: 0,
      ),
      body: _rulesFuture == null
          ? _buildFilePickerScreen()
          : _buildRulesListScreen(),
    );
  }

  Widget _buildFilePickerScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_open,
            size: 80,
            color: Colors.blue.withAlpha((255 * 0.5).toInt()),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a Validation Rules JSON File',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose a JSON file containing validation rules from your file system',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Browse and Select File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesListScreen() {
    return FutureBuilder<List<ValidationRule>>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red.withAlpha((255 * 0.5).toInt()),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading file',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rulesFuture = null;
                      _selectedFilePath = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Select Different File'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey.withAlpha((255 * 0.5).toInt()),
                ),
                const SizedBox(height: 16),
                const Text('No validation rules found in this file'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rulesFuture = null;
                      _selectedFilePath = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Select Different File'),
                ),
              ],
            ),
          );
        }

        _allRules = snapshot.data!;
        _allEntityTypes =
            ValidationRulesService.getAllEntityTypes(_allRules);
        _applyFilters(_allRules);

        return Column(
          children: [
            // File info and change button
            Container(
              color: Colors.blue.withAlpha((255 * 0.1).toInt()),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.file_present, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current File:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _selectedFilePath?.split(Platform.pathSeparator).last ??
                              'No file selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _rulesFuture = null;
                        _selectedFilePath = null;
                      });
                    },
                    icon: const Icon(Icons.change_circle),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            // Filter and Search Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Entity Type Filter
                  DropdownButton<String?>(
                    isExpanded: true,
                    hint: const Text('Filter by Entity Type'),
                    value: _selectedEntityType,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Entity Types'),
                      ),
                      ..._allEntityTypes.map((type) {
                        return DropdownMenuItem<String?>(
                          value: type,
                          child: Text(type),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEntityType = value;
                        _applyFilters(_allRules);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Search Box
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by description or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters(_allRules);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${_filteredRules.length} of ${_allRules.length} rules',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _filteredRules.isEmpty ? null : _showPdfPreview,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(
                        'Export ${_filteredRules.length} Selected Rules as PDF',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rules List
            Expanded(
              child: _filteredRules.isEmpty
                  ? const Center(child: Text('No rules match the filters'))
                  : ListView.builder(
                      itemCount: _filteredRules.length,
                      itemBuilder: (context, index) {
                        final rule = _filteredRules[index];
                        return ValidationRuleCard(
                          rule: rule,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ValidationRuleDetailScreen(rule: rule),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ValidationRuleCard extends StatelessWidget {
  final ValidationRule rule;
  final VoidCallback onTap;

  const ValidationRuleCard({
    super.key,
    required this.rule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: rule.isEnabled
                    ? Colors.green.withAlpha((255 * 0.2).toInt())
                    : Colors.grey.withAlpha((255 * 0.2).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                'ID: ${rule.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rule.isEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          rule.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: rule.entityTypeNames
                  .map((type) => Chip(
                        label: Text(
                          type,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            Text(
              'Enabled: ${rule.isEnabled ? 'Yes' : 'No'} | '
              'Create: ${rule.runOnCreate ? 'Yes' : 'No'} | '
              'Update: ${rule.runOnUpdate ? 'Yes' : 'No'} | '
              'Delete: ${rule.runOnDelete ? 'Yes' : 'No'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class ValidationRuleDetailScreen extends StatelessWidget {
  final ValidationRule rule;

  const ValidationRuleDetailScreen({super.key, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rule #${rule.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            _DetailSection(
              title: 'Description',
              child: Text(
                rule.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Error Message
            if (rule.errorMessage != null)
              _DetailSection(
                title: 'Error Message',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.1).toInt()),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    rule.errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            // Entity Types
            _DetailSection(
              title: 'Entity Types',
              child: Wrap(
                spacing: 8,
                children: rule.entityTypeNames
                    .map((type) => Chip(
                          label: Text(type),
                          backgroundColor: Colors.blue.withAlpha((255 * 0.2).toInt()),
                        ))
                    .toList(),
              ),
            ),
            // Changed Fields
            if (rule.changedFieldNames.isNotEmpty)
              _DetailSection(
                title: 'Changed Fields',
                child: Wrap(
                  spacing: 8,
                  children: rule.changedFieldNames
                      .map((field) => Chip(label: Text(field)))
                      .toList(),
                ),
              ),
            // Triggers
            _DetailSection(
              title: 'When Does This Rule Trigger?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TriggerRow('On Create', rule.runOnCreate),
                  _TriggerRow('On Update', rule.runOnUpdate),
                  _TriggerRow('On Delete', rule.runOnDelete),
                ],
              ),
            ),
            // DSL Condition
            _DetailSection(
              title: 'DSL Condition (Validation Logic)',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((255 * 0.1).toInt()),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  rule.dslCondition,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            // Status
            _DetailSection(
              title: 'Status',
              child: Container(
                decoration: BoxDecoration(
                  color: rule.isEnabled
                      ? Colors.green.withAlpha((255 * 0.1).toInt())
                      : Colors.red.withAlpha((255 * 0.1).toInt()),
                  border: Border.all(
                    color: rule.isEnabled ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  rule.isEnabled ? '✓ Enabled' : '✗ Disabled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rule.isEnabled ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            // Metadata
            _DetailSection(
              title: 'Metadata',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${rule.id}'),
                  Text('Version: ${rule.version}'),
                  Text('Created by User ID: ${rule.createdByUserId}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationRulesPdfPreview extends StatelessWidget {
  final List<ValidationRule> rules;

  const _ValidationRulesPdfPreview({required this.rules});

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final document = pdf_w.Document();

    document.addPage(
      pdf_w.MultiPage(
        pageFormat: format,
        header: (context) => pdf_w.Container(
          //margin: const pw.EdgeInsets.only(bottom: 16),
          child: pdf_w.Row(
            mainAxisAlignment: pdf_w.MainAxisAlignment.spaceBetween,
            children: [
              pdf_w.Text(
                'Validation Rule Reader',
                style: pdf_w.TextStyle(
                  fontSize: 12,
                  fontWeight: pdf_w.FontWeight.bold,
                ),
              ),
              pdf_w.Text('${rules.length} selected rules'),
            ],
          ),
        ),
        build: (context) => [
          pdf_w.Text(
            'Validation Rules Summary',
            style: pdf_w.TextStyle(fontSize: 12, fontWeight: pdf_w.FontWeight.bold),
          ),
          pdf_w.SizedBox(height: 9),
          pdf_w.TableHelper.fromTextArray(
            headers: const ['ID', 'Description', 'Entity Types', 'Status'],
            data: rules
                .map(
                  (rule) => [
                    rule.id.toString(),
                    rule.description,
                    rule.entityTypeNames.join(', '),
                    rule.isEnabled ? 'Y' : 'N',
                  ],
                )
                .toList(),
            headerStyle: pdf_w.TextStyle(fontWeight: pdf_w.FontWeight.bold),
            cellStyle: const pdf_w.TextStyle(fontSize: 9),
            headerDecoration: const pdf_w.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pdf_w.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    return document.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Rules Summary')),
      body: PdfPreview(
        build: _buildPdf,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        pdfFileName: 'validation-rules-summary.pdf',
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TriggerRow extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TriggerRow(this.label, this.isActive);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
