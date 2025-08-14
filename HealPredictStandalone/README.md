# HealPredictStandalone

A standalone heal prediction addon for Ascension WoW based on ElvUI architecture.

## Features

- **Standalone Operation**: No dependencies required, all libraries integrated
- **Automatic Frame Detection**: Detects Blizzard and popular addon unit frames
- **Visual Heal Prediction**: Shows incoming heals with colored bars
- **Configurable Interface**: `/healpredict config` to open settings
- **Performance Optimized**: Uses efficient callback system
- **Ascension Compatible**: Designed for Ascension WoW (Interface 30300)

## Installation

1. Extract to your `Interface/AddOns/` folder
2. Restart World of Warcraft
3. Enable the addon in your addon list

## Usage

### Commands
- `/healpredict config` - Open configuration window
- `/healpredict debug` - Toggle debug mode
- `/healpredict status` - Show addon status

### Configuration
The addon automatically detects unit frames from:
- Blizzard default frames
- ElvUI
- ShadowedUnitFrames
- PitBull
- X-Perl
- Grid
- VuhDo
- HealBot

### Visual Elements
- **Green bars**: Your incoming heals
- **Blue bars**: Other players' incoming heals
- **Overflow protection**: Configurable maximum overflow (default 105%)

## Architecture

The addon follows a 3-layer architecture:

1. **HealPredict Library** - Core heal prediction and communication
2. **oUF Plugin** - Integration layer for unit frame systems
3. **UI Elements** - Visual representation and configuration

### Files Structure
```
HealPredictStandalone/
├── HealPredictStandalone.toc     # Addon manifest
├── Core.lua                      # Main system initialization
├── Libraries/
│   ├── HealPredict/             # Core prediction library
│   ├── oUF/                     # Minimal oUF framework
│   └── oUF_Plugins/             # Unit frame integration
├── Modules/
│   └── UnitFrames/              # Frame detection and management
└── Settings/
    └── Config.lua               # Configuration interface
```

## API

For addon developers, HealPredictStandalone provides a public API:

### HealPredict Library
```lua
-- Register callback for heal updates
HealPredict.RegisterCallback("MyAddon", function(...)
    local units = {...}
    -- Handle heal updates for units
end)

-- Get incoming heals for a unit
local myHeals = HealPredict.UnitGetIncomingHeals("player", UnitName("player"))
local allHeals = HealPredict.UnitGetIncomingHeals("player")
```

### Addon Integration
```lua
local HPS = _G.HealPredictStandalone
if HPS then
    -- Check if addon is loaded and initialized
    if HPS.IsInitialized() then
        -- Use addon features
    end
end
```

## Compatibility

- **Interface Version**: 30300 (3.3.5a)
- **Ascension WoW**: Fully supported
- **Server Types**: PvP, PvE, Seasonal

## Troubleshooting

### Common Issues

**Bars not showing:**
1. Check if heal prediction is enabled (`/healpredict status`)
2. Try refreshing frame detection (`/healpredict config` → Refresh Frames)
3. Enable debug mode to see detection messages

**Performance issues:**
1. Reduce max overflow setting
2. Disable detection for unused frame types
3. Check for conflicting addons

### Debug Information

Enable debug mode with `/healpredict debug` to see:
- Frame detection messages
- Heal prediction updates
- Configuration changes

## Credits

Based on the ElvUI heal prediction system:
- **Original Authors**: Elv, Bunny (ElvUI Team)
- **Adaptation**: For Ascension WoW standalone use
- **Architecture**: 3-layer system from ElvUI design

## Version History

### 1.0.0
- Initial release
- Core heal prediction functionality
- Automatic frame detection
- Basic configuration interface
- Ascension WoW compatibility