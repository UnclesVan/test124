-- This LocalScript should be placed in StarterPlayer > StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService") -- Added for task.wait() if not already there

-- --- Module Paths ---
-- Path to the Pet Me Ailment module
local PET_ME_AILMENT_MODULE_PATH = ReplicatedStorage.new.modules.Ailments.AilmentsDB.pet_me

-- Load Fsys module (assuming it's in ReplicatedStorage)
local FsysLoad = require(ReplicatedStorage:WaitForChild("Fsys")).load

-- Load UIManager via Fsys (which contains FocusPetApp)
local UIManager = FsysLoad("UIManager")
-- Access the FocusPetApp instance (which is 'var9' from its decompiled code)
local FocusPetApp = UIManager.apps.FocusPetApp
-- Access the petting_handler (which is 'arg1.petting_handler' within FocusPetApp)
local petting_handler = FocusPetApp.petting_handler

-- Load PetEntityManager via Fsys (used to get the actual pet entity table)
local PetEntityManager = FsysLoad("PetEntityManager")


-- --- Main Logic ---

-- Function to find and wrap a pet model into a basic entity
local function findAndWrapPetModel()
    local petCharModel = nil
    local petsFolder = Workspace:FindFirstChild("Pets")

    if petsFolder and petsFolder:IsA("Folder") then
        for _, child in ipairs(petsFolder:GetChildren()) do
            -- Find a model that looks like a pet (has Humanoid and HumanoidRootPart)
            if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                petCharModel = child
                print("Found pet character model from Workspace.Pets:", child.Name)
                break
            end
        end
    end

    if not petCharModel then
        warn("Failed to find a pet character model in Workspace.Pets.")
        return nil
    end

    return petCharModel
end


-- Main execution function
local function startPettingLogic()
    print("--- Starting Petting Logic ---")

    -- 1. Find the actual pet character model (e.g., the 'Starter Egg' model)
    local petCharModel = findAndWrapPetModel()
    if not petCharModel then
        warn("No suitable pet model found. Cannot proceed with petting.")
        return
    end

    -- 2. Verify PetEntityManager is available
    if not PetEntityManager or not PetEntityManager.get_pet_entity then
        warn("Could not load PetEntityManager or find its 'get_pet_entity' method. Cannot proceed.")
        return
    end

    -- 3. Call FocusPetApp.capture_focus with the pet character model
    -- 'capture_focus' expects 'arg2' to be a table with a 'char' property,
    -- where 'char' is the actual Roblox model of the pet/character.
    local captureFocusArg = {
        char = petCharModel
    }

    -- Call 'capture_focus' as a method on the FocusPetApp instance.
    -- This sets up the internal 'pet_entity' within FocusPetApp and its sub-modules like petting_handler.
    FocusPetApp:capture_focus(captureFocusArg)
    print("Called FocusPetApp:capture_focus with pet character model:", petCharModel.Name)

    -- Give it a moment for the internal state to update after capture_focus.
    -- This is crucial for the petting_handler to have its pet_entity properly set.
    task.wait(0.5)

    -- 4. Get and trigger the Pet Me ailment action
    local PetMeAilment = require(PET_ME_AILMENT_MODULE_PATH)
    local petMeAction = PetMeAilment.create_action()

    if typeof(petMeAction) == "table" and typeof(petMeAction.callback) == "function" then
        print("Executing Pet Me ailment action callback...")
        -- This call will execute the internal function from pet_me.create_action()
        -- which contains:
        -- local petting_handler = LegacyLoad_result1_upvr.apps.FocusPetApp.petting_handler
        -- petting_handler:show_example()
        -- petting_handler:start_petting()
        petMeAction:callback()
        print("Successfully triggered petting via Pet Me ailment action's callback.")
    else
        warn("PetMeAilment.create_action() did not return an action table with a 'callback' function.")
    end

    print("--- Petting Logic Finished ---")
end

-- Use RunService.Stepped or a simple task.spawn to ensure the script runs after
-- the game is sufficiently loaded (e.g., character exists, services are ready).
-- This is often better than just running immediately at the top level of the script.
RunService.Stepped:Wait() -- Wait at least one frame to ensure everything is initialized

-- Small delay to let the game fully load components like UIManager if needed
task.wait(1)

-- Now, run the main logic
startPettingLogic()
