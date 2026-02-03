// Offline-First Architecture Patterns for Quanitya Tracker App
// 
// This file documents the architectural patterns and principles for implementing
// offline-first functionality with PowerSync integration.

// Offline-first data access patterns
abstract class OfflineFirstPatterns {
  // Pattern 1: Read-Local-First
  // Always read from local plaintext tables for immediate access.
  static const String readLocalFirst = 'Read from local tables only';
  
  // Pattern 2: Write-Local-Then-Sync
  // Write to local tables immediately, sync to encrypted tables in background.
  static const String writeLocalThenSync = 'Write local, sync encrypted';
  
  // Pattern 3: Conflict-Free-Resolution
  // Use timestamps for automatic conflict resolution.
  static const String conflictFreeResolution = 'Last-write-wins with timestamps';
}