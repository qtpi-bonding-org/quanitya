# Quanitya Architecture Documentation

## Overview

Quanitya is a privacy-first personal tracking app built with Flutter. It uses end-to-end encryption (E2EE) to ensure user data never leaves the device in plaintext.

## Core Architecture Diagrams

### Template Generation Pipeline

```mermaid
graph TB
    %% PHASE 1: SYMBOLIC COMBINATION GENERATION
    subgraph PHASE1["🔸 PHASE 1: SYMBOLIC COMBINATION GENERATION"]
        subgraph BASE_ENUMS["Base Enums"]
            FE["FieldEnum<br/>integer, float, text, boolean, datetime<br/>enumerated, dimension, reference"]
            UEE["UiElementEnum<br/>slider, textField, textArea, stepper<br/>chips, dropdown, radio, toggleSwitch<br/>checkbox, datePicker, timePicker<br/>datetimePicker, searchField"]
            VTE["ValidatorType<br/>optional, numeric, text, enumerated<br/>dimension, reference, custom"]
        end
        
        subgraph COUPLING["UI-Validator Coupling"]
            UVC["UiValidatorCoupling<br/>• Slider ↔ Numeric<br/>• Dropdown ↔ Enumerated<br/>• TextField ↔ Text (optional)<br/>• Switch ↔ None"]
        end
        
        subgraph COMBINATIONS["Valid Combinations"]
            SCG["SymbolicCombinationGenerator<br/>→ (FieldEnum, UiElementEnum, ValidatorType[]) tuples"]
        end
    end
    
    %% PHASE 2: SCHEMA GENERATION
    subgraph PHASE2["🔹 PHASE 2: SCHEMA GENERATION"]
        subgraph TEMPLATE_GEN["Template Generation"]
            JDWTG["WidgetTemplateGenerator<br/>• Maps field+widget → colorable properties<br/>• Generates widget templates"]
        end
        
        subgraph REGISTRY["Widget Registry"]
            QWR["QuanityaWidgetRegistry<br/>• ColorableWidgetSchema per widget<br/>• toJsonSchema() for AI constraints"]
        end
        
        subgraph SCHEMA["Schema Output"]
            USG["UnifiedSchemaGenerator<br/>• Combines templates + registry<br/>• Produces JSON Schema for AI"]
        end
    end
    
    %% RUNTIME: NATIVE FLUTTER (Two Paths)
    subgraph RUNTIME["🟢 RUNTIME: Native Flutter Widgets"]
        subgraph PARSING["AI Output Parsing"]
            JMP["JsonToModelParser<br/>• Parses AI JSON response<br/>• Creates TrackerTemplateModel<br/>• Creates TemplateAestheticsModel"]
        end
        
        subgraph STORAGE["Persistence"]
            DB["Database<br/>• Save template + aesthetics<br/>• Load on demand"]
        end
        
        subgraph BUILDER["Widget Builder"]
            DFB["DynamicFieldBuilder<br/>• Builds form widgets from TemplateField<br/>• Resolves colors from aesthetics<br/>• Returns native Flutter widgets"]
        end
        
        subgraph WIDGETS["Native Widgets"]
            QS["QuanityaSlider"]
            QT["QuanityaToggle"]
            QTF["QuanityaTextField"]
            QC["QuanityaCheckbox"]
            QD["QuanityaDropdown"]
            QRG["QuanityaRadioGroup"]
            QCG["QuanityaChipGroup"]
            QST["QuanityaStepper"]
            QDP["QuanityaDatePicker"]
            QTP["QuanityaTimePicker"]
        end
        
        subgraph OUTPUT["Rendered UI"]
            FW["Flutter Widget Tree<br/>• Hot reload supported ⚡<br/>• Native performance"]
        end
    end
    
    %% Flow connections
    FE --> UVC
    UEE --> UVC
    VTE --> UVC
    UVC --> SCG
    
    SCG --> JDWTG
    JDWTG --> USG
    QWR --> USG
    
    USG -->|"JSON Schema"| AI["AI (OpenAI/Anthropic)"]
    AI -->|"Template JSON"| JMP
    JMP --> DB
    DB -->|"Load template"| DFB
    
    DFB --> QS & QT & QTF & QC & QD & QRG & QCG & QST & QDP & QTP
    QS & QT & QTF & QC & QD & QRG & QCG & QST & QDP & QTP --> FW
    
    %% Styling
    classDef phase1 fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef phase2 fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    classDef runtime fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    
    class PHASE1 phase1
    class PHASE2 phase2
    class RUNTIME runtime
```

### Data Flow (PII-Less E2EE)

```mermaid
graph TB
    %% UI Layer
    UI[UI Layer - Cubits]
    
    %% Repository Layer
    subgraph REPO[Repository Layer]
        TR[TrackerTemplateRepo<br/>Business Logic]
        SR[ScheduleRepo<br/>Business Logic]
        LR[LogEntryRepo<br/>Business Logic]
    end
    
    %% Dual DAO Layer
    subgraph DAO[Dual DAO Layer - Transactional Writes]
        subgraph TD[TrackerTemplateDualDAO]
            TDP[TablePairs.trackerTemplate<br/>tracker_templates ↔ encrypted_templates]
        end
        
        subgraph SD[ScheduleDualDAO]
            SDP[TablePairs.schedule<br/>schedules ↔ encrypted_schedules]
        end
        
        subgraph LD[LogEntryDualDAO]
            LDP[TablePairs.logEntry<br/>log_entries ↔ encrypted_entries]
        end
    end
    
    %% Database Layer
    subgraph DB[Single Drift Database - PowerSync Integration]
        subgraph LOCAL[Local Tables - Plaintext PII]
            LT[tracker_templates]
            LS[schedules]
            LE[log_entries]
        end
        
        subgraph ENCRYPTED[Encrypted Shadow Tables - E2EE]
            ET[encrypted_templates]
            ES[encrypted_schedules]
            EE[encrypted_entries]
        end
    end
    
    %% PowerSync Layer
    subgraph PS[PowerSync Layer]
        PSD[PowerSyncDatabase<br/>Syncs ONLY encrypted_* tables]
    end
    
    %% Backend
    subgraph BACKEND[Serverpod Backend - PostgreSQL]
        BET[encrypted_templates]
        BES[encrypted_schedules]
        BEE[encrypted_entries]
    end
    
    %% Outgoing Flow
    UI --> REPO
    TR --> TD
    SR --> SD
    LR --> LD
    TD --> LT & ET
    SD --> LS & ES
    LD --> LE & EE
    
    %% PowerSync Flow
    ET & ES & EE --> PSD
    PSD --> BET & BES & BEE
```

## Key Components

| Layer | Component | Location | Purpose |
|-------|-----------|----------|---------|
| Enums | FieldEnum | `lib/logic/templates/enums/` | Data types |
| Enums | UiElementEnum | `lib/logic/templates/enums/` | Widget types |
| Enums | ValidatorType | `lib/logic/templates/models/shared/` | Validation rules |
| Engine | SymbolicCombinationGenerator | `lib/logic/templates/services/engine/` | Valid combinations |
| Engine | UnifiedSchemaGenerator | `lib/logic/templates/services/engine/` | JSON Schema for AI |
| Widgets | QuanityaWidgetRegistry | `lib/design_system/widgets/quanitya/generatable/` | Widget schemas |
| Widgets | DynamicFieldBuilder | `lib/logic/templates/services/shared/` | Runtime widget builder |
| Data | Dual DAOs | `lib/data/daos/` | E2EE transactional writes |
| State | Cubits | `lib/features/*/cubits/` | UI state management |

## Development Standards

See `.kiro/steering/` for:
- `quanitya_development_standards.md` - Freezed, Drift, Cubits, Injectable patterns
- `cubit_ui_flow_pattern.md` - Automatic UI feedback system
- `flutter_color_palette_guide.md` - Enumerated color system
- `pii-less.md` - E2EE architecture details

## Generating API Documentation

```bash
# Generate dartdoc
dart doc .

# Output will be in doc/api/
```
