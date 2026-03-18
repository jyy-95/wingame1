# Azure Planet Merge TD

A desktop single-player Merge tower defense roguelike prototype built with Godot 4.

## Included in this prototype

- 5-wave stage flow with a boss on wave 5
- Random summon, 20-slot board, drag-to-merge, right-click sell
- Global trait draft and evolution trait draft
- Poison, crit, and frost core totems
- Random events between waves
- Local save for unlocked stage and last seed

## Open the project

1. Open Godot 4.x.
2. Click Import.
3. Select `project.godot` in this folder.
4. Open the imported project.

## Run

- Press F5 to run the main scene.
- If Godot asks for a main scene, choose `res://scenes/main/main.tscn`.

## Controls

- `Summon Hero`: summon one random hero from the current preview pool
- `Refresh Preview`: refresh the preview pool
- Drag one hero onto another matching hero to merge
- Right click a hero to sell it

## Headless smoke test

If `godot4` is available in PATH:

```powershell
godot4 --headless --path . -s res://tests/run_smoke_tests.gd
```