# Firestore Indexes Fix

## Issue
Firebase deployment error: "this index is not necessary, configure using single field index controls"

## Solution
Removed single-field indexes that Firestore creates automatically:
- ❌ `groupMembers`: userId (single field - removed)
- ❌ `events`: startDate (single field - removed)

## What Remains
All composite indexes (2+ fields) are kept, as these are required for queries that combine:
- Multiple `where` clauses
- `where` clauses with `orderBy` on different fields
- Range queries with `orderBy`

## Single-Field Indexes
Firestore automatically creates single-field indexes for:
- Simple `where` queries on one field
- Simple `orderBy` queries on one field
- Range queries (`>=`, `<=`) with `orderBy` on the same field

These do NOT need to be explicitly defined in `firestore.indexes.json`.

## Composite Indexes Required
All remaining indexes in `firestore.indexes.json` are composite indexes (2+ fields) that are required for:
- Queries with multiple `where` clauses + `orderBy`
- Queries with `where` + `orderBy` on different fields
- Complex filtering and sorting

## Deployment
The indexes file should now deploy successfully:
```bash
firebase deploy --only firestore:indexes
```

