# Project Status

## Current milestone

M1 — Document Library

## M0 — completed

- App bootstrapping entry point and ProviderScope root
- Material 3 light/dark themes
- Home / Files / Tools / Settings navigation
- Drift v1 schema for core local entities
- Safe local file writes
- Universal `WorkKitAction` extension contract
- Unit/widget/database test foundation
- GitHub Actions quality workflow
- First green CI and merge to `main`

## M1 — implemented in current branch

- Native file picker adapter
- Import by copying source files into WorkKit-managed local storage
- Persistent document metadata in Drift/SQLite
- Reactive recent documents on Home
- Search by document name/type
- Favorites filter and favorite toggle
- Rename display name without moving the managed file
- Delete confirmation and managed-file cleanup
- Share/export through the platform share sheet
- Image preview thumbnails rendered from local files
- Local library storage usage summary
- Repository and import lifecycle tests

## Next code task

Run CI for M1, fix any analyzer/test issues, merge M1, then generate and commit Android/iOS platform projects before M2 scanner integration.
