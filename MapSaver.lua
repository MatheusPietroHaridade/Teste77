--[[
    Map Saver / Importer para Studio Lite
    Loadstring exemplo:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/MapSaver.lua", true))()
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remove GUI antiga se existir
if PlayerGui:FindFirstChild("MapSaverGui") then
    PlayerGui.MapSaverGui:Destroy()
end

local FILE_NAME = "SavedMap.lua"

----------------------------------------------------------------------
-- SERIALIZER
----------------------------------------------------------------------
local function serializeCFrame(cf)
    local components = {cf:GetComponents()}
    return "CFrame.new(" .. table.concat(components, ", ") .. ")"
end

local function serializeColor3(c)
    return string.format("Color3.new(%.4f, %.4f, %.4f)", c.R, c.G, c.B)
end

local counter = 0
local function getVar()
    counter = counter + 1
    return "o" .. counter
end

local function serialize(obj, parentVar, indent)
    indent = indent or ""
    local className = obj.ClassName

    -- Ignora MeshPart e qualquer coisa que não seja Part/Model/Folder
    if className == "MeshPart" then
        return ""
    end
    if not (className == "Part" or className == "Model" or className == "Folder") then
        return ""
    end

    local code = ""
    local var = getVar()

    if className == "Part" then
        code = code .. indent .. "local " .. var .. " = Instance.new(\"Part\")\n"
        code = code .. indent .. var .. ".Name = " .. string.format("%q", obj.Name) .. "\n"
        code = code .. indent .. var .. ".Size = Vector3.new(" .. 
            string.format("%.4f, %.4f, %.4f", obj.Size.X, obj.Size.Y, obj.Size.Z) .. ")\n"
        code = code .. indent .. var .. ".CFrame = " .. serializeCFrame(obj.CFrame) .. "\n"
        code = code .. indent .. var .. ".Color = " .. serializeColor3(obj.Color) .. "\n"
        code = code .. indent .. var .. ".Material = Enum.Material." .. obj.Material.Name .. "\n"
        code = code .. indent .. var .. ".Transparency = " .. obj.Transparency .. "\n"
        code = code .. indent .. var .. ".Reflectance = " .. obj.Reflectance .. "\n"
        code = code .. indent .. var .. ".CanCollide = " .. tostring(obj.CanCollide) .. "\n"
        code = code .. indent .. var .. ".Anchored = true\n"  -- sempre anchored no import
        if obj.Shape ~= Enum.PartType.Block then
            code = code .. indent .. var .. ".Shape = Enum.PartType." .. obj.Shape.Name .. "\n"
        end
        code = code .. indent .. var .. ".Parent = " .. parentVar .. "\n"

    elseif className == "Model" or className == "Folder" then
        code = code .. indent .. "local " .. var .. " = Instance.new(\"" .. className .. "\")\n"
        code = code .. indent .. var .. ".Name = " .. string.format("%q", obj.Name) .. "\n"
        code = code .. indent .. var .. ".Parent = " .. parentVar .. "\n"

        for _, child in ipairs(obj:GetChildren()) do
            code = code .. serialize(child, var, indent .. "    ")
        end
    end

    return code
end

local function generateSaveCode()
    counter = 0
    local code = [[
-- Mapa salvo automaticamente
-- Gerado para uso no Studio Lite
local mapFolder = Instance.new("Folder")
mapFolder.Name = "ImportedMap"
mapFolder.Parent = workspace

]]

    for _, child in ipairs(workspace:GetChildren()) do
        -- Evita salvar o personagem do player e coisas do sistema
        if child.Name ~= "Camera" and not child:IsA("Terrain") and not Players:GetPlayerFromCharacter(child) then
            code = code .. serialize(child, "mapFolder", "")
        end
    end

    code = code .. "\nprint(\"[MapSaver] Mapa importado com sucesso!\")\n"
    return code
end

----------------------------------------------------------------------
-- SALVAR
----------------------------------------------------------------------
local function salvarMapa()
    local success, err = pcall(function()
        local code = generateSaveCode()

        if writefile then
            writefile(FILE_NAME, code)
            print("[MapSaver] Mapa salvo em:", FILE_NAME)
            -- Notificação visual simples
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "MapSaver",
                Text = "Mapa salvo com sucesso!",
                Duration = 4
            })
        elseif setclipboard then
            setclipboard(code)
            print("[MapSaver] Código copiado para a clipboard!")
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "MapSaver",
                Text = "Código copiado para clipboard!",
                Duration = 4
            })
        else
            error("Seu executor não tem writefile nem setclipboard")
        end
    end)

    if not success then
        warn("[MapSaver] Erro ao salvar:", err)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MapSaver - Erro",
            Text = tostring(err),
            Duration = 6
        })
    end
end

----------------------------------------------------------------------
-- IMPORTAR
----------------------------------------------------------------------
local function importarMapa()
    local success, err = pcall(function()
        local code

        if isfile and isfile(FILE_NAME) then
            code = readfile(FILE_NAME)
        elseif getclipboard then
            code = getclipboard()
        else
            error("Nenhum mapa encontrado (nem arquivo nem clipboard)")
        end

        if not code or #code < 50 then
            error("Código do mapa inválido ou vazio")
        end

        -- Executa o código gerado
        local func, loadErr = loadstring(code)
        if not func then
            error("Erro ao carregar código: " .. tostring(loadErr))
        end

        func()

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MapSaver",
            Text = "Mapa importado com sucesso!",
            Duration = 4
        })
    end)

    if not success then
        warn("[MapSaver] Erro ao importar:", err)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MapSaver - Erro",
            Text = tostring(err),
            Duration = 6
        })
    end
end

----------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MapSaverGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, 140)
Main.Position = UDim2.new(0.5, -110, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Title.BorderSizePixel = 0
Title.Text = "Map Saver"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Botão SalvarMapa (verde)
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.85, 0, 0, 36)
SaveBtn.Position = UDim2.new(0.075, 0, 0, 50)
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
SaveBtn.Text = "SalvarMapa"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 15
SaveBtn.Parent = Main

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 8)
SaveCorner.Parent = SaveBtn

-- Botão ImportarMapa (vermelho)
local ImportBtn = Instance.new("TextButton")
ImportBtn.Size = UDim2.new(0.85, 0, 0, 36)
ImportBtn.Position = UDim2.new(0.075, 0, 0, 95)
ImportBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ImportBtn.Text = "ImportarMapa"
ImportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ImportBtn.Font = Enum.Font.GothamBold
ImportBtn.TextSize = 15
ImportBtn.Parent = Main

local ImportCorner = Instance.new("UICorner")
ImportCorner.CornerRadius = UDim.new(0, 8)
ImportCorner.Parent = ImportBtn

-- Conexões
SaveBtn.MouseButton1Click:Connect(salvarMapa)
ImportBtn.MouseButton1Click:Connect(importarMapa)

print("[MapSaver] Menu carregado com sucesso!")
