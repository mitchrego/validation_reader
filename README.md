# Validation Rule Reader

A Flutter app to view and analyze validation rules from JSON configuration files.

## Features

✅ **File Picker** - Browse and select JSON files from your file system (no hardcoded assets)
✅ **View All Validation Rules** - Browse the complete list of validation rules with key information at a glance
✅ **Filter by Entity Type** - Dropdown filter to show rules for specific entity types (ProjectTask, Budget, Cost, etc.)
✅ **Search Functionality** - Search rules by description or rule ID
✅ **Detailed Rule View** - Click any rule to see complete information including:
   - Rule description and error message
   - Entity types it applies to
   - Fields that trigger the rule
   - When it triggers (onCreate, onUpdate, onDelete)
   - DSL condition (the validation logic)
   - Current status (enabled/disabled)
   - Metadata (ID, version, created by)
✅ **Change File** - Switch between different JSON files at any time

## Understanding Validation Rules

Each validation rule controls what changes are allowed to specific entity types. Here's what each property means:

- **ID**: Unique identifier for the rule
- **Description**: What this rule prevents or enforces
- **Error Message**: The error shown to users if the rule fails
- **Entity Types**: Which entities this rule applies to
- **Changed Fields**: Which fields trigger this rule when modified
- **DSL Condition**: The logic that determines if validation fails
  - If this evaluates to **TRUE**, the validation fails and the operation is blocked
  - If this evaluates to **FALSE**, the validation passes and the operation is allowed
- **Triggers**:
  - onCreate: Rule checks when new entities are created
  - onUpdate: Rule checks when entities are updated
  - onDelete: Rule checks when entities are deleted
- **Status**: Whether the rule is currently active

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run on Web
flutter run -d web
```

When you launch the app, you'll see a file picker screen. Click "Browse and Select File" to choose your validation rules JSON file from anywhere on your system.

## File Format Requirements

The JSON file should have the following structure:

```json
{
  "items": [
    {
      "id": 1,
      "version": 21091937,
      "description": "Rule description",
      "errorMessage": "Error message to show users",
      "entityTypeNames": ["EntityType1", "EntityType2"],
      "changedFieldNames": ["Field1", "Field2"],
      "runOnCreate": true,
      "runOnUpdate": true,
      "runOnDelete": false,
      "dslCondition": "validation logic here",
      "createdByUserId": 17,
      "isEnabled": true
    }
  ]
}
```

## Building for Production

```bash
# Build for Windows
flutter build windows

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Build for Web
flutter build web
```

## Project Structure

```
validation_reader/
├── lib/
│   └── main.dart           # Complete app with models, services, and UI
├── pubspec.yaml            # Flutter dependencies and configuration
└── test/
    └── widget_test.dart    # Basic app tests
```

## Key Components

### Models
- **ValidationRule**: Represents a single validation rule with all its properties

### Services
- **ValidationRulesService**: Loads and parses the JSON file, extracts unique entity types

### Screens
- **ValidationRulesScreen**: Main screen with filtering and searching
- **ValidationRuleDetailScreen**: Detailed view of a selected rule

### Widgets
- **ValidationRuleCard**: List item card showing rule summary
- **_DetailSection**: Reusable section component for the detail view
- **_TriggerRow**: Shows trigger status (enabled/disabled)

## Customization

The app now works with any JSON file matching the validation rules format:

1. Click "Browse and Select File" when you launch the app
2. Navigate to your validation rules JSON file (e.g., `RJ SB Validation.json`)
3. The app will automatically parse and display all rules
4. Use "Change" button in the file info bar to switch to a different JSON file
