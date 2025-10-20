## Bright-Minds — Copilot instructions for automated coding agents

These notes give concise, actionable context for AI coding agents working in this repository. Keep responses short and focused; prefer making small, verifiable edits and running quick checks.

Key structure
- Client (Flutter app): `client/` — Flutter project with platform folders (android, ios, web, windows, macos, linux). Main entry: `client/lib/main.dart`. Use `pubspec.yaml` for dependencies and `client/README.md` for basic info.
- Server (Node.js API): `Server/` — Minimal Express API. Entry point: `Server/index.js`. Server package info and run script: `Server/package.json` (script `serve`: `node index.js`).

Big-picture architecture
- The repo contains a Flutter client and a small Node.js server. The client handles the UI and likely calls the server API for backend data. The server is a lightweight Express app listening on port 3000 (`Server/index.js`).
- Data persistence references appear via `mongodb` in `client/package.json` and lockfiles, suggesting expected backend DB integration. However, the `Server` folder currently has no DB wiring (check `Server/controllers/` and `Server/routers/` for future integrations).

Developer workflows (how to run & test locally)
- Start server (from `Server/`):

```powershell
cd Server; npm install; npm run serve
```

- Run Flutter client (from `client/`): use Flutter tooling on your OS. From repo root:

```powershell
cd client; flutter pub get; flutter run
```

Project-specific patterns and conventions
- Server is intentionally minimal. Common patterns to follow when adding features:
  - Keep routing logic under `Server/routers/` and business logic under `Server/controllers/`.
  - Export router modules and mount them in `Server/index.js` (currently `index.js` only defines a root GET).
  - Use `Server/package.json` for server dependencies (currently only `express` is declared).
- The client folder is a standard Flutter app — follow Flutter conventions for widgets, state management (none enforced), and platform-specific code under `client/android`, `client/ios`, etc.

Integration & cross-component notes
- The repo likely expects the client to call the Node server at `http://localhost:3000`. When adding endpoints, update client API URLs accordingly (search for API call locations in the Flutter codebase).
- There is evidence of `mongodb` in the workspace lockfiles and `client/package.json`; if adding DB access on the server, prefer the official `mongodb` Node driver and store connection configuration in environment variables (do not hardcode credentials).

What to change and how to validate
- Small feature PRs should:
  - Add/modify server routes in `Server/routers/*` and logic in `Server/controllers/*`.
  - Update `Server/package.json` only when adding dependencies and include any new npm scripts used for development.
  - Add minimal unit tests where possible (server currently lacks a test framework; prefer Jest or Mocha if adding tests).
- Validation steps (after code changes):
  1. From `Server/`: `npm install` then `npm run serve` and exercise the new endpoint with curl or Postman.
  2. From `client/`: `flutter pub get` and run on an emulator to ensure API integration works.

Examples / places to look
- Server entrypoint: `Server/index.js` (simple Express app listening on port 3000).
- Server metadata: `Server/package.json` (script `serve`).
- Client entrypoint: `client/lib/main.dart` and `client/pubspec.yaml` for dependencies.
- Where to add server features: `Server/routers/` and `Server/controllers/` (create files if missing).

Rules for edits by AI agents
- Make minimal, testable PRs. Prefer adding one feature/fix per PR with a short description and manual verification steps.
- Do not add secrets or real credentials to the repo. If environment variables are required, add a `.env.example` and mention the required vars in the PR description.
- When introducing new dependencies, prefer well-known, maintained packages and add a one-line justification in the PR body.

If anything here is unclear or you'd like more detail on build/test workflows, point me to files you'd like inspected and I'll expand this file.
