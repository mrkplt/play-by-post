# Play-by-Post TTRPG

A web application for asynchronous tabletop role-playing games. Game masters and players collaborate on scenes through threaded posts, with email notifications and email-to-post functionality.

## Features

- Magic link authentication (no passwords)
- Games with scenes organized in a parent/child hierarchy
- Threaded posts with Markdown support and image attachments
- Character sheets with full version history
- Out-of-character post filtering
- Player invitations and GM-controlled member management
- Email notifications (new scenes, post digests, scene resolution)
- Reply-by-email (post to a scene by replying to a notification)

## Running Locally

**Requirements:** Ruby 4.0.2, Bundler, Node.js (for Playwright)

```sh
bin/setup        # install dependencies, install git hooks, prepare database, start server
```

`bin/setup` is idempotent — safe to re-run. It starts the server automatically when done. To set up without starting the server:

```sh
bin/setup --skip-server
bin/dev          # starts Rails (port 3000) + Tailwind CSS watcher
```

Email previews are available at `http://localhost:3000/letter_opener` in development.

## Deployment

Self-hosted on Coolify. Images are built by GitHub Actions and pulled from GHCR;
builds do not run on the deployment host. See [DEPLOY.md](DEPLOY.md) for the runbook.

**Production stack:**
- Build: Docker, via `.github/workflows/build-image.yml` (arm64)
- Database: SQLite on a mounted volume, shared by the web and worker containers
- File storage: Cloudflare R2 (via Active Storage)
- Email: Resend (inbound + outbound)
- LLM: OpenRouter (inbound email parsing, scene summaries)
- Jobs: Solid Queue (dedicated worker container, no Redis)
- Cache: Solid Cache (database-backed)

`bin/docker-entrypoint` runs `db:prepare` when the server starts, which creates and
migrates the primary, cache and queue databases.

Health check endpoint: `GET /up`

**Configuration:** [docs/CONFIGURATION.md](docs/CONFIGURATION.md) is the source of truth
for every environment variable and credential, each with the file and line that reads it.
Do not restate config values here.

## Quality

Guard rails enforced on every push:

- **RuboCop** — style and static analysis
- **Brakeman** — Rails security vulnerabilities
- **importmap audit** — JavaScript dependency vulnerabilities
- **Sorbet** — gradual type checking
- **RSpec + SimpleCov** — tests with line and branch coverage thresholds
- **Mutant** — mutation testing on changed files
- **`bin/quality-metrics`** — per-file and aggregate quality gates

All checks run automatically via `bin/pre-push` before code is pushed. The pipeline exits on the first failure.

### Pre-push pipeline

| Step | Tool | What it does |
|---|---|---|
| Lint | [RuboCop](https://rubocop.org/) | Enforces Ruby style and static analysis rules |
| JS security scan | `importmap audit` | Checks JavaScript dependencies for known vulnerabilities |
| Ruby security scan | [Brakeman](https://brakemanscanner.org/) | Static analysis for common Rails security vulnerabilities |
| Type check | [Sorbet](https://sorbet.org/) (`srb tc`) | Gradual type checking across the codebase |
| Tests | [RSpec](https://rspec.info/) | Unit and integration tests with [SimpleCov](https://github.com/simplecov-ruby/simplecov) coverage (line + branch) |
| Mutation testing | [Mutant](https://github.com/mbj/mutant) (`--since origin/master`) | Verifies tests detect code mutations in changed files |
| Quality metrics | `bin/quality-metrics --check` | Enforces overall and per-file quality gates (see below) |

### Quality gates (`bin/quality-metrics --check`)

**Overall baseline regression** — aggregate metrics cannot regress more than 5 percentage points from the stored baseline (`quality_baseline.json`):

- Line coverage (SimpleCov)
- Branch coverage (SimpleCov)
- Sorbet typed file percentage ([Spoom](https://github.com/Shopify/spoom))
- Mutation coverage (Mutant) — treated as a minimum floor rather than a regression target

**Per changed file** — every `.rb` file in `app/` and `lib/` modified since `origin/master` must individually meet:

- Line coverage >= 80%
- Branch coverage >= 70%
- Sorbet sigil of `true`, `strict`, or `strong`

### Commands

```sh
bin/quality-metrics              # display current metrics
bin/quality-metrics --save       # save current metrics as the new baseline
bin/quality-metrics --check      # run all quality gates
```

https://railsdesigner.com/open-source/rails-icons/hugeicons/