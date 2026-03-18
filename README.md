# Azure Planet Merge TD

A desktop single-player Merge tower defense roguelike prototype built with Godot 4.

## Included in this prototype

- 5-wave stage flow with a boss on wave 5
- Battlefield-first desktop battle UI with a 20-slot deploy strip
- Pure random summon, drag-to-merge, right-click sell
- Poison, crit, and frost core totems with in-run upgrades
- Global trait draft and evolution trait draft
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

- `Summon Hero`: summon one random hero from the weighted pool
- `Upgrade Totem`: spend gold to raise the selected core totem level
- Drag one hero onto another matching hero to merge
- Right click a hero to sell it
- Left rail buttons toggle speed, run intel, and battle log

## Headless smoke test

If `godot4` is available in PATH:

```powershell
godot4 --headless --path . -s res://tests/run_smoke_tests.gd
```
