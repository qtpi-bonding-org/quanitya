# PII-Less Architecture with E2EE Dual DAO + Stream-Based Puller

## Data Model Overview

```
TrackerTemplateModel  →  "WHAT" (the form structure)
ScheduleModel         →  "WHEN" (the reminder rules)
LogEntryModel         →  "ACTUAL" (the recorded data)
```

## Complete Data Flow Diagram

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
            LT[tracker_templates<br/>- id, name, fields_json<br/>- updated_at, is_archived]
            LS[schedules<br/>- id, template_id, recurrence_rule<br/>- reminder_offset_minutes, is_active<br/>- last_generated_at, updated_at]
            LE[log_entries<br/>- id, template_id<br/>- scheduled_for, occurred_at<br/>- data_json]
        end
        
        subgraph ENCRYPTED[Encrypted Shadow Tables - E2EE]
            ET[encrypted_templates]
            ES[encrypted_schedules]
            EE[encrypted_entries]
        end
    end
    
    %% PowerSync Layer
    subgraph PS[PowerSync Layer]
        PSD[PowerSyncDatabase<br/>- Monitors ONLY encrypted_* tables<br/>- Syncs encrypted data to PostgreSQL]
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

## Table Pairs

| Model | Local Table | Encrypted Table | TablePair |
|-------|-------------|-----------------|-----------|
| TrackerTemplateModel | tracker_templates | encrypted_templates | `TablePairs.trackerTemplate(db)` |
| ScheduleModel | schedules | encrypted_schedules | `TablePairs.schedule(db)` |
| LogEntryModel | log_entries | encrypted_entries | `TablePairs.logEntry(db)` |

## Key Architecture Components

### 1. **Dual DAO Layer (Outgoing)**
- **Purpose**: App writes with encryption
- **Pattern**: Transactional writes to both local + encrypted tables
- **Type Safety**: TablePair pattern prevents table mix-ups
- **Flow**: `App → Repository → DualDAO → [Local + Encrypted] → PowerSync`

### 2. **E2EE Puller (Incoming)**
- **Purpose**: PowerSync sync with decryption
- **Pattern**: Stream-based listeners with type-safe processors
- **Type Safety**: Same TablePair pattern as Dual DAO
- **Flow**: `PowerSync → Encrypted → Drift Streams → Processors → Local`

### 3. **Data Flow Directions**
```
OUTGOING (App Writes):
App → DualDAO → Local + Encrypted → PowerSync → Backend

INCOMING (Sync Receives):
Backend → PowerSync → Encrypted → E2EE Puller → Local
```

### 4. **PII Protection Guarantees**
- ✅ **Local tables**: Never synced, PII stays on device
- ✅ **Encrypted tables**: Only encrypted blobs sync to backend
- ✅ **PowerSync**: No access to plaintext data
- ✅ **Backend**: Only receives encrypted data, zero PII exposure

### 5. **Type Safety Benefits**
- ✅ **Compile-time pairing**: TablePairs prevent wrong table combinations
- ✅ **No mix-ups**: TrackerTemplate, Schedule, and LogEntry processors isolated
- ✅ **Consistent patterns**: Same TablePair used in both Dual DAO and E2EE Puller
- ✅ **Extensible**: Easy to add new table pairs with same safety guarantees
