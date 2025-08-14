# HealPredictionAddon

A WoW 3.3.5 addon that provides heal prediction functionality compatible with WoW Ascension.

## Features Included

### Enhanced Functionality for Ascension
- **Element-based architecture** adapted from ElvUI's working heal prediction system
- **Dual compatibility** - works with both modern element-based frames and legacy Blizzard frames  
- **Missing API stubs** for functions not available in Ascension (UnitIsControlled, UnitIsDisarmed)
- **Improved error handling** and null checks for robust operation
- **Configurable colors** and overflow settings
- **Auto-detection** of common unit frames (Player, Target, Focus, Party)

### Core Functionality
- `UnitGetIncomingHeals(unit, healer)` - Get incoming heal amounts for a unit
- `HealComm4` element system for modern unit frame integration
- Visual templates for myHealPrediction and otherHealPrediction bars
- Event handling for LibHealComm callbacks (HealComm_HealStarted, HealComm_HealUpdated, etc.)
- Support for LibStub and LibHealComm-4.0

### Libraries Included
- LibStub - Library versioning system
- CallbackHandler-1.0 - Callback handling system (required by LibHealComm)
- LibHealComm-4.0 - Heal communication library

### Templates
- MyHealPredictionBarTemplate - Visual template for player's own heals (teal color)
- OtherHealPredictionBarTemplate - Visual template for other players' heals (darker teal)
- HealPredictionTemplate - Main frame template combining both bars

## Features Removed/Excluded

- Absorb shields functionality (totalAbsorb, healAbsorb) - not available in WotLK/Ascension
- Mana cost prediction
- CompactRaidFrame references
- AceComm/ChatThrottleLib dependencies  
- BuilderSpender functionality
- All non-heal prediction related code

## File Structure

```
HealPredictionAddon/
├── HealPredictionAddon.toc           # WoW 3.3.5 addon definition
├── Core/
│   ├── HealPrediction.lua            # Core API functions + missing API stubs
│   ├── Config.lua                    # Configuration system
│   ├── HealComm4.lua                 # Modern element-based heal prediction
│   ├── EnhancedHealBars.lua          # Auto-detection and enhanced integration
│   └── LegacyHealBars.lua            # Fallback for legacy unit frames
├── Libs/
│   ├── LibStub/LibStub.lua           # Library versioning system
│   ├── CallbackHandler-1.0/          # Callback handling (LibHealComm dependency)
│   └── LibHealComm-4.0/              # Heal communication library
└── Templates/
    └── HealPredictionTemplates.xml   # Visual templates for heal bars
```

## Installation

Place the HealPredictionAddon folder in your `Interface/AddOns/` directory and restart WoW.

## Compatibility

- **WoW 3.3.5** (Wrath of the Lich King)
- **WoW Ascension** - Specifically adapted for Ascension's modified API
- Works with standard Blizzard unit frames
- Compatible with modern element-based unit frame addons
- Independent of other addons

## Changes for Ascension Compatibility

### API Adaptations
- Added stub implementations for `UnitIsControlled` and `UnitIsDisarmed` (missing in Ascension)
- Enhanced error handling for missing or null unit GUIDs
- Improved timeout handling for heal prediction queries
- Better handling of edge cases in heal amount calculations

### Architecture Improvements
- **Element system**: Proper HealComm4 element that can be enabled/disabled on frames
- **Configuration system**: Color and overflow settings like ElvUI
- **Auto-detection**: Automatically detects and sets up heal prediction on common frames
- **Dual compatibility**: Works with both modern and legacy unit frame systems
- **Robust integration**: Better positioning and sizing logic adapted from ElvUI

### Based on ElvUI's Working Implementation
This adaptation incorporates the working patterns from ElvUI's heal prediction system:
- Element-based architecture (`HealComm4` element)
- Proper color configuration and overflow handling  
- Enhanced bar positioning and sizing logic
- Robust parent management based on overflow settings
- Orientation handling (horizontal/vertical)