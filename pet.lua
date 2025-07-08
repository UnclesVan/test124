-- This LocalScript should be placed in StarterPlayer > StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- --- Module Paths ---
local PET_ME_AILMENT_MODULE_PATH = ReplicatedStorage.new.modules.Ailments.AilmentsDB.pet_me
local FsysLoad = require(ReplicatedStorage:WaitForChild("Fsys")).load

-- Load UIManager and its components directly
local UIManager = FsysLoad("UIManager")
local FocusPetApp = UIManager.apps.FocusPetApp
local petting_handler = FocusPetApp.petting_handler
local AilmentsApp = FocusPetApp.ailments
local PetEntityManager = FsysLoad("PetEntityManager")


-- --- Main Logic ---

local function startPettingLogic()
    print("--- Starting Petting Logic ---")

    local petToFocusEntity = nil

    local ownedPets = PetEntityManager.get_local_owned_pet_entities()
    if #ownedPets > 0 then
        petToFocusEntity = ownedPets[1]
        print("Found a player-owned pet entity:", petToFocusEntity.base.char.Name)
    else
        warn("No player-owned pet entities found via PetEntityManager.get_local_owned_pet_entities().")
        local petsFolder = Workspace:FindFirstChild("Pets")
        if petsFolder and petsFolder:IsA("Folder") then
            for _, child in ipairs(petsFolder:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                    warn("Found a pet model in Workspace.Pets, but focusing on owned pets first.")
                    break
                end
            end
        end

        if not petToFocusEntity then
            warn("No PetEntity available. Cannot proceed.")
            return
        end
    end

    -- --- DIAGNOSTIC PRINTS (initial checks) ---
    print("PetEntity .base:", petToFocusEntity.base)
    print("PetEntity .base.char:", petToFocusEntity.base.char)
    if petToFocusEntity.base.char then
        print("PetEntity .base.char.Parent:", petToFocusEntity.base.char.Parent)
        print("PetEntity .base.char:IsA('Model'):", petToFocusEntity.base.char:IsA("Model"))
        print("PetEntity .base.char.HumanoidRootPart:", petToFocusEntity.base.char:FindFirstChild("HumanoidRootPart"))
        print("PetEntity .base.char:FindFirstChild('PetModel'):", petToFocusEntity.base.char:FindFirstChild("PetModel"))
        print("PetEntity .base.char.char_wrapper:", petToFocusEntity.base.char_wrapper)
    else
        warn("PetEntity.base.char is NIL. This pet likely does not have a physical character model.")
    end
    -- --- END DIAGNOSTIC PRINTS ---

    print("Waiting for pet entity char_wrapper.client_has_control to be true...")
    local waitStartTime = tick()
    local timeout = 5 -- seconds
    local success = false
    while tick() - waitStartTime < timeout do
        if petToFocusEntity.base and petToFocusEntity.base.char_wrapper and petToFocusEntity.base.char_wrapper.char then
            if petToFocusEntity.base.char.Parent == Workspace.Pets then
                 if petToFocusEntity.base.char_wrapper.client_has_control then
                    success = true
                    break
                 end
            end
        end
        task.wait(0.1)
    end

    if not success then
        warn("Timeout: petToFocusEntity.base.char_wrapper.client_has_control never became true. Attempting to force FocusPetApp state.")
    else
        print("petToFocusEntity.base.char_wrapper.client_has_control is now true.")
    end

    print("Bypassing FocusPetApp.capture_focus due to client_has_control issue.")

    -- Manually set properties on FocusPetApp
    FocusPetApp.char_wrapper = petToFocusEntity
    FocusPetApp.pet_entity = petToFocusEntity

    -- Conditionally call capture_focus on relevant sub-apps ONLY if petToFocusEntity.base.char exists
    -- AND it has the expected "PetModel" child.
    if petToFocusEntity.base.char and petToFocusEntity.base.char:FindFirstChild("PetModel") then
        print("Pet has a character model and 'PetModel' child. Attempting to capture_focus on camera, ailments, pet_selector, and petting_handler.")

        -- *** IMMEDIATE PRE-CAPTURE_FOCUS CHECKS ***
        print("--- IMMEDIATE PRE-CAPTURE_FOCUS CHECKS ---")
        local preCheckChar = petToFocusEntity.base.char
        print("Pre-capture_focus check: petToFocusEntity.base.char (value):", preCheckChar)
        print("Pre-capture_focus check: petToFocusEntity.base.char.Parent (value):", preCheckChar.Parent)
        print("Pre-capture_focus check: petToFocusEntity.base.char:FindFirstChild('HumanoidRootPart') (value):", preCheckChar:FindFirstChild("HumanoidRootPart"))
        print("Pre-capture_focus check: petToFocusEntity.base.char:FindFirstChild('PetModel') (value):", preCheckChar:FindFirstChild("PetModel"))
        print("--- END IMMEDIATE PRE-CAPTURE_FOCUS CHECKS ---")
        -- ****************************************************

        -- Wrap problematic calls in pcall
        local cameraSuccess, cameraError = pcall(function()
            if FocusPetApp.camera then FocusPetApp.camera:capture_focus(petToFocusEntity) end
        end)
        if not cameraSuccess then
            warn("FocusPetApp.camera:capture_focus failed: " .. tostring(cameraError))
        end

        local ailmentsSuccess, ailmentsError = pcall(function()
            if AilmentsApp then AilmentsApp:capture_focus(petToFocusEntity) end
        end)
        if not ailmentsSuccess then
            warn("AilmentsApp:capture_focus failed: " .. tostring(ailmentsError))
        end

        local petSelectorSuccess, petSelectorError = pcall(function()
            if FocusPetApp.pet_selector then FocusPetApp.pet_selector:capture_focus(petToFocusEntity) end
        end)
        if not petSelectorSuccess then
            warn("FocusPetApp.pet_selector:capture_focus failed: " .. tostring(petSelectorError))
        end

        local pettingHandlerSuccess, pettingHandlerError = pcall(function()
            if FocusPetApp.petting_handler then FocusPetApp.petting_handler:capture_focus(petToFocusEntity) end
        end)
        if not pettingHandlerSuccess then
            warn("FocusPetApp.petting_handler:capture_focus failed: " .. tostring(pettingHandlerError))
        end

    else
        warn("Pet's character model is missing OR is missing the 'PetModel' child. Skipping capture_focus for camera, ailments, pet_selector, and petting_handler.")
        warn("This may mean the 'Starter Egg' cannot be directly interacted with by these FocusPetApp modules.")
    end

    FocusPetApp.UIManager.set_app_visibility(FocusPetApp.ClassName, true)
    FocusPetApp:show()

    print("Manually initiated FocusPetApp state.")

    task.wait(0.5)

    local pet_entity_from_handler = petting_handler.pet_entity

    if not pet_entity_from_handler then
        warn("petting_handler.pet_entity is NIL even after manual capture_focus. Cannot proceed with petting. (This is expected if pet.base.char or 'PetModel' was NIL)")
        return
    end

    local PetMeAilment = require(PET_ME_AILMENT_MODULE_PATH)

    local customAilmentCallback = function()
        petting_handler.pet_entity = pet_entity_from_handler
        print("Ensuring petting_handler.pet_entity is set before calling show_example/start_petting. Pet:", petting_handler.pet_entity.base.char.Name)

        -- These might also fail if pet.base.char or its children (like HumanoidRootPart or PetModel) are missing.
        -- We're calling them anyway to see the direct error if it occurs.
        local showExampleSuccess, showExampleError = pcall(function()
            petting_handler:show_example()
        end)
        if not showExampleSuccess then
            warn("petting_handler:show_example() failed: " .. tostring(showExampleError))
        end

        local startPettingSuccess, startPettingError = pcall(function()
            petting_handler:start_petting()
        end)
        if not startPettingSuccess then
            warn("petting_handler:start_petting() failed: " .. tostring(startPettingError))
        end
        return true
    end

    print("Manually triggering petting handler functions...")
    customAilmentCallback()

    print("--- Petting Logic Finished ---")
end

RunService.Stepped:Wait()
task.wait(1)

startPettingLogic()
