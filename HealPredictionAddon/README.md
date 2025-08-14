# HealPredictionAddon

A minimal WoW 3.3.5 addon that provides heal prediction functionality extracted from UnitFrameLayers.

## Features Included

### Core Functionality
- `UnitGetIncomingHeals(unit, healer)` - Get incoming heal amounts for a unit
- `UnitFrameHealPredictionBars_Update(frame)` - Update heal prediction bars on unit frames  
- `UnitFrameUtil_UpdateFillBar()` - Utility function for updating fill bars
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

- Absorb shields functionality (totalAbsorb, healAbsorb) 
- Mana cost prediction
- CompactRaidFrame references
- AceComm/ChatThrottleLib dependencies
- BuilderSpender functionality
- All non-heal prediction related code

## File Structure

```
HealPredictionAddon/
├── HealPredictionAddon.toc        # WoW 3.3.5 addon definition
├── Core/
│   ├── HealPrediction.lua         # Core API functions for heal prediction
│   └── UnitFrameHealBars.lua      # Visual display logic for heal bars
├── Libs/
│   ├── LibStub/LibStub.lua        # Library versioning system
│   ├── CallbackHandler-1.0/       # Callback handling (LibHealComm dependency)
│   └── LibHealComm-4.0/           # Heal communication library
└── Templates/
    └── HealPredictionTemplates.xml # Visual templates for heal bars
```

## Installation

Place the HealPredictionAddon folder in your `Interface/AddOns/` directory and restart WoW.

## Compatibility

- WoW 3.3.5 (Wrath of the Lich King)
- Works with standard Blizzard unit frames
- Independent of other addons