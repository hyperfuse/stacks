# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Setup and Installation:**
```bash
mix setup                    # Install deps, setup database, build assets
mix deps.get                 # Install Elixir dependencies
```

**Development Server:**
```bash
mix phx.server              # Start Phoenix server
iex -S mix phx.server       # Start server in interactive shell
```

**Database Operations:**
```bash
mix ecto.create             # Create database
mix ecto.migrate            # Run migrations
mix ecto.reset              # Drop and recreate database
```

**Testing:**
```bash
mix test                    # Run all tests
mix test test/path/to/specific_test.exs  # Run specific test file
```

**Assets:**
```bash
mix assets.build            # Build CSS/JS assets
mix assets.deploy           # Build and minify for production
```

**Chrome Extension (chrome/ directory):**
```bash
cd chrome && pnpm dev       # Development mode
cd chrome && pnpm build     # Build extension
cd chrome && pnpm package   # Package for distribution
```

## Architecture Overview

This is a Phoenix application with a Chrome extension for content enrichment:

**Core Architecture:**
- **Phoenix Backend**: REST API and web interface for managing items
- **Chrome Extension**: Plasmo-based extension for capturing web content
- **Background Jobs**: Oban-powered job processing for content enrichment
- **Database**: PostgreSQL with Ecto for data persistence

**Key Components:**

1. **Items System** (`lib/stacks/items.ex`): Core domain for managing saved content with CRUD operations via `Stacks.Items` context

2. **API Layer** (`lib/stacks_web/router.ex`): RESTful API at `/api/items` with CORS enabled for Chrome extension integration

3. **Background Processing** (`lib/stacks_jobs/jobs.ex`): `WebpageEnricher` worker uses Readability library to extract article content, title, and metadata from URLs

4. **Chrome Extension** (`chrome/`): TypeScript/React extension with context menu integration and host permissions for all HTTPS sites

**Data Flow:**
1. Chrome extension sends URLs to `/api/items` endpoint
2. Items are created in database
3. `WebpageEnricher` job is queued to process the URL
4. Job extracts article content and updates item metadata
5. Enriched content is available via API

**Development Notes:**
- Uses Oban for reliable background job processing
- Corsica enables cross-origin requests for Chrome extension
- LiveDashboard available at `/dev/dashboard` in development
- Items have `source_url` and `metadata` fields for enriched content