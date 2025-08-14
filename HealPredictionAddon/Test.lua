--[[
	HealPredictionAddon - Simple Test Script
	
	This script can be used to test basic functionality of the heal prediction addon
	Run in-game with /script or /run
]]

local function TestHealPrediction()
	print("=== HealPredictionAddon Test ===")
	
	-- Test 1: Check if core API functions exist
	print("Test 1: Core API Functions")
	if UnitGetIncomingHeals then
		print("✓ UnitGetIncomingHeals exists")
		
		-- Test with player unit
		local playerHeals = UnitGetIncomingHeals("player")
		print("Player incoming heals: " .. (playerHeals or 0))
		
		local playerSelfHeals = UnitGetIncomingHeals("player", "player")  
		print("Player self heals: " .. (playerSelfHeals or 0))
	else
		print("✗ UnitGetIncomingHeals missing")
	end
	
	-- Test 2: Check missing API stubs
	print("\nTest 2: Missing API Stubs")
	if UnitIsControlled then
		print("✓ UnitIsControlled exists")
		local isControlled = UnitIsControlled("player")
		print("Player controlled: " .. tostring(isControlled))
	else
		print("✗ UnitIsControlled missing")
	end
	
	if UnitIsDisarmed then
		print("✓ UnitIsDisarmed exists") 
		local isDisarmed = UnitIsDisarmed("player")
		print("Player disarmed: " .. tostring(isDisarmed))
	else
		print("✗ UnitIsDisarmed missing")
	end
	
	-- Test 3: Check HealPredictionAddon object
	print("\nTest 3: Addon Object")
	if HealPredictionAddon then
		print("✓ HealPredictionAddon exists")
		
		if HealPredictionAddon.config then
			print("✓ Config system loaded")
			local colors = HealPredictionAddon.config.colors.healPrediction
			if colors then
				print("Personal heal color: r=" .. colors.personal.r .. " g=" .. colors.personal.g .. " b=" .. colors.personal.b)
				print("Others heal color: r=" .. colors.others.r .. " g=" .. colors.others.g .. " b=" .. colors.others.b)
			end
		else
			print("✗ Config system missing")
		end
		
		if HealPredictionAddon.EnableHealComm4 then
			print("✓ Element system functions exist")
		else
			print("✗ Element system functions missing")
		end
	else
		print("✗ HealPredictionAddon missing")
	end
	
	-- Test 4: Check unit frames
	print("\nTest 4: Unit Frame Integration")
	local frames = {
		PlayerFrame = PlayerFrame,
		TargetFrame = TargetFrame,
		FocusFrame = FocusFrame
	}
	
	for name, frame in pairs(frames) do
		if frame then
			print("✓ " .. name .. " exists")
			if frame.HealCommBar then
				print("  - Has HealCommBar element")
				if frame.HealCommBar.myBar and frame.HealCommBar.otherBar then
					print("  - Has prediction bars")
				else
					print("  - Missing prediction bars")
				end
			else
				print("  - No HealCommBar element")
			end
		else
			print("✗ " .. name .. " not found")
		end
	end
	
	-- Test 5: LibHealComm integration
	print("\nTest 5: LibHealComm Integration")
	local HealComm = LibStub:GetLibrary("LibHealComm-4.0", true)
	if HealComm then
		print("✓ LibHealComm-4.0 loaded")
		if HealComm.GetHealAmount then
			print("✓ HealComm functions available")
		else
			print("✗ HealComm functions missing")  
		end
	else
		print("✗ LibHealComm-4.0 not found")
	end
	
	print("\n=== Test Complete ===")
end

-- Run the test
TestHealPrediction()

-- Also provide a command to run manually
SLASH_TESTheal1 = "/testheal"
SlashCmdList["TESTEAL"] = TestHealPrediction