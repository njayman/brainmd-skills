# Tool Reference

Full schemas and usage examples for all brain.md MCP tools.

## Read/Search Tools

### search_notes

Full-text search across the vault.

```json
{
  "query": "machine learning notes",
  "scope": "Research/AI"
}
```

- `query` (required): Search terms
- `scope` (optional): Folder path to limit search

Returns: Array of matching notes with paths, scores, and snippets.

### similar_notes

Semantic/vector search via RAG embedding similarity.

```json
{
  "query": "how does backpropagation work",
  "k": 5
}
```

- `query` (required): Natural language query
- `k` (optional): Number of results (default varies by instance)

Returns: Array of semantically similar notes with similarity scores.

### read_note

Read a single note's content.

```json
{
  "path": "Research/AI/neural-networks.md"
}
```

- `path` (required): Note path within the vault

Returns: Note content (markdown) + mtime metadata.

### list_notes

List all notes and folders.

```json
{
  "folder": "Projects"
}
```

- `folder` (optional): Folder path to list (defaults to root)

Returns: Array of note/folder entries with paths and types.

## Knowledge Graph Tools

### get_backlinks

Get notes that link to a given note.

```json
{
  "path": "Research/AI/neural-networks.md"
}
```

Returns: Array of notes containing links to the given path.

### find_related

Find notes semantically close to a given note.

```json
{
  "path": "Research/AI/neural-networks.md",
  "k": 5,
  "scope": "Research"
}
```

- `path` (required): Source note
- `k` (optional): Number of results
- `scope` (optional): Folder to search within

Returns: Array of related notes with similarity scores.

### semantic_outline

Cluster a note's chunks into topical groups.

```json
{
  "path": "Research/AI/deep-learning-survey.md"
}
```

Returns: Topical clusters with representative chunks.

### compare_notes

Compare two notes for similarity, diff, and shared structure.

```json
{
  "path_a": "Research/AI/note-a.md",
  "path_b": "Research/AI/note-b.md"
}
```

Returns: Cosine similarity score, unified diff, and shared headings.

## Task Tools

### get_tasks

Aggregate tasks from across the vault.

```json
{
  "filter": "open"
}
```

- `filter` (optional): `"open"`, `"done"`, or `"all"` (default: `"open"`)

Returns: Array of task items with status and source note.

### find_similar_tasks

Semantic search across task lines.

```json
{
  "query": "deploy the API"
}
```

Returns: Matching task items with similarity scores.

## Write Tools

### write_note

Create or overwrite a note.

```json
{
  "path": "Todos/weekly.md",
  "content": "# Weekly Tasks\n\n- [ ] Review PRs\n- [ ] Update docs"
}
```

- `path` (required): Note path
- `content` (required): Full note body (markdown)

### append_note

Append content to a note with a blank-line separator.

```json
{
  "path": "Journal/2026-07-13.md",
  "content": "## Afternoon\n\nFinished the API migration."
}
```

- `path` (required): Note path
- `content` (required): Content to append

## Context Tools

### context_for_query

Pack the most relevant chunks under a token budget. Ideal for RAG injection.

```json
{
  "query": "how to set up OAuth with brain.md",
  "budget_tokens": 4000
}
```

- `query` (required): What to find context for
- `budget_tokens` (optional): Max tokens to return

Returns: Packed context chunks fitting within the budget.

### find_orphans

Find notes with zero backlinks and low semantic neighbors.

```json
{
  "min_isolation": 0.7
}
```

- `min_isolation` (optional): Isolation threshold 0-1 (higher = more isolated)

Returns: Array of orphaned notes.

### weekly_digest

Generate topic clusters from recently modified notes.

```json
{
  "since": "7d"
}
```

- `since` (optional): Time window (`"24h"`, `"7d"`, `"30d"`)

Returns: Topic clusters with note counts and summaries.

### list_tags

List all tags with usage counts. No parameters.

Returns: Array of `{tag, count}` objects.

### current_datetime

Get the server's current date, time, and timezone. No parameters.

Returns: `{datetime, timezone}` object.
