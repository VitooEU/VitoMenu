task.spawn(function()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local guiName = "VitoCustomRadialMenu"
pcall(function()
	if game:GetService("CoreGui"):FindFirstChild(guiName) then
		game:GetService("CoreGui")[guiName]:Destroy()
	end
end)
pcall(function()
	local pg = player:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild(guiName) then
		pg[guiName]:Destroy()
	end
end)
pcall(function()
	if Lighting:FindFirstChild("RadialMenuBlur") then
		Lighting.RadialMenuBlur:Destroy()
	end
end)

local sg = Instance.new("ScreenGui")
sg.Name = guiName
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true

local success = pcall(function()
    sg.Parent = game:GetService("CoreGui")
end)
if not success then
    sg.Parent = player:WaitForChild("PlayerGui")
end

local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://876939830"
hoverSound.Volume = 2

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "RadialMenuBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local isMenuOpen = false
local clickBlocker = Instance.new("TextButton")
clickBlocker.Name = "VT_EmoteClickBlocker"
clickBlocker.Size = UDim2.new(1, 0, 1, 0)
clickBlocker.BackgroundTransparency = 1
clickBlocker.Text = ""
clickBlocker.Visible = false
clickBlocker.Active = true
clickBlocker.Parent = sg

local container = Instance.new("Frame")
container.Name = "RadialContainer"
container.Size = UDim2.new(0, 800, 0, 800)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = sg

local uiScale = Instance.new("UIScale")
uiScale.Parent = container

local ringSize = 260
local ringThickness = 160

local ring = Instance.new("Frame")
ring.Size = UDim2.new(0, ringSize, 0, ringSize)
ring.Position = UDim2.new(0.5, 0, 0.5, 0)
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.BackgroundTransparency = 1
ring.Parent = container

local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = ring

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.fromRGB(0, 0, 0)
ringStroke.Transparency = 0.4
ringStroke.Thickness = ringThickness
ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ringStroke.Parent = ring

for i = 1, 8 do
	local angle = math.rad(i * 45 + 22.5)
	local lineCenterDist = (ringSize / 2) + (ringThickness / 2)
	
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 4, 0, ringThickness)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.new(0.5, math.cos(angle) * lineCenterDist, 0.5, math.sin(angle) * lineCenterDist)
	line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	line.BackgroundTransparency = 0.6
	line.BorderSizePixel = 0
	line.Rotation = math.deg(angle) + 90
	line.Parent = container
end

local centerText = Instance.new("TextLabel")
centerText.Size = UDim2.new(0, 160, 0, 80)
centerText.Position = UDim2.new(0.5, 0, 0.5, 0)
centerText.AnchorPoint = Vector2.new(0.5, 0.5)
centerText.BackgroundTransparency = 1
centerText.TextColor3 = Color3.fromRGB(255, 255, 255)
centerText.Font = Enum.Font.GothamBold
centerText.TextSize = 20
centerText.TextWrapped = true
centerText.Text = ""
centerText.Parent = container

---------------------------------------------------------
-- NEUE FUNKTIONEN: Suche, Favoriten & Seiten
---------------------------------------------------------

local HttpService = game:GetService("HttpService")
local emotesList = {}
local emotesCacheFile = "VT_Menu_EmotesCache_V2.json"

pcall(function()
	if isfile and isfile(emotesCacheFile) then
		local content = readfile(emotesCacheFile)
		if content and content ~= "" then
			emotesList = HttpService:JSONDecode(content)
		end
	end
end)

if #emotesList == 0 then
	local success, result = pcall(function()
		local jsonContent = game:HttpGet("https://raw.githubusercontent.com/VitooEU/Emotes/refs/heads/main/All_Emotes.json")
		if jsonContent and jsonContent ~= "" then
			return HttpService:JSONDecode(jsonContent)
		end
		return {}
	end)
	
	if success and type(result) == "table" and #result > 0 then
		for _, item in pairs(result) do
			if item.id and item.name then
				table.insert(emotesList, {
					id = tonumber(item.id), 
					name = item.name, 
					type = item.type or "Asset"
				})
			end
		end
	end
	
	if #emotesList == 0 then
		emotesList = {
			{id = 3360686498, name = "Stadium", type = "Asset"},
			{id = 4689362868, name = "Line Dance", type = "Asset"}
		}
	else
		pcall(function()
			if writefile then
				writefile(emotesCacheFile, HttpService:JSONEncode(emotesList))
			end
		end)
	end
end

local allItems = emotesList
local favFileName = "VT_Menu_Favorites.json"
local favItems = {}

pcall(function()
	if isfile and isfile(favFileName) then
		local content = readfile(favFileName)
		if content and content ~= "" then
			favItems = HttpService:JSONDecode(content)
		end
	end
end)

local function saveFavorites()
	pcall(function()
		if writefile then
			writefile(favFileName, HttpService:JSONEncode(favItems))
		end
	end)
end

local currentPage = 1
local searchQuery = ""
local currentDisplayedItems = {}
local currentEmoteTrack = nil
local currentMoveConnection = nil

local searchBox = Instance.new("TextBox")
searchBox.Active = true
searchBox.Size = UDim2.new(0, 240, 0, 40)
searchBox.Position = UDim2.new(0.5, 0, 0.5, -380)
searchBox.AnchorPoint = Vector2.new(0.5, 0.5)
searchBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
searchBox.BackgroundTransparency = 0.5
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "Search..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 16
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.Parent = container
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local pageLeft = Instance.new("TextButton")
pageLeft.Active = true
pageLeft.Size = UDim2.new(0, 40, 0, 40)
pageLeft.Position = UDim2.new(0.5, -60, 0.5, 320)
pageLeft.AnchorPoint = Vector2.new(0.5, 0.5)
pageLeft.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pageLeft.BackgroundTransparency = 0.5
pageLeft.Text = "<"
pageLeft.TextColor3 = Color3.fromRGB(255, 255, 255)
pageLeft.TextSize = 20
pageLeft.Parent = container
local plCorner = Instance.new("UICorner")
plCorner.CornerRadius = UDim.new(0, 8)
plCorner.Parent = pageLeft

local pageRight = Instance.new("TextButton")
pageRight.Active = true
pageRight.Size = UDim2.new(0, 40, 0, 40)
pageRight.Position = UDim2.new(0.5, 60, 0.5, 320)
pageRight.AnchorPoint = Vector2.new(0.5, 0.5)
pageRight.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pageRight.BackgroundTransparency = 0.5
pageRight.Text = ">"
pageRight.TextColor3 = Color3.fromRGB(255, 255, 255)
pageRight.TextSize = 20
pageRight.Parent = container
local prCorner = Instance.new("UICorner")
prCorner.CornerRadius = UDim.new(0, 8)
prCorner.Parent = pageRight

local pageLabel = Instance.new("TextLabel")
pageLabel.Size = UDim2.new(0, 60, 0, 40)
pageLabel.Position = UDim2.new(0.5, 0, 0.5, 320)
pageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
pageLabel.BackgroundTransparency = 1
pageLabel.Text = "1 / 1"
pageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pageLabel.TextSize = 18
pageLabel.Font = Enum.Font.GothamBold
pageLabel.Parent = container

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 300, 0, 20)
hintLabel.Position = UDim2.new(0.5, 0, 0.5, 350)
hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "Right click to favorite"
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.TextSize = 14
hintLabel.Font = Enum.Font.Gotham
hintLabel.Parent = container

local isHoveringUI = false
local function setHovering() isHoveringUI = true end
local function setNotHovering() isHoveringUI = false end

searchBox.MouseEnter:Connect(function()
	setHovering()
	TweenService:Create(searchBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
end)
searchBox.MouseLeave:Connect(function()
	setNotHovering()
	TweenService:Create(searchBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
end)

pageLeft.MouseEnter:Connect(function()
	setHovering()
	TweenService:Create(pageLeft, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, Size = UDim2.new(0, 46, 0, 46)}):Play()
end)
pageLeft.MouseLeave:Connect(function()
	setNotHovering()
	TweenService:Create(pageLeft, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 40, 0, 40)}):Play()
end)

pageRight.MouseEnter:Connect(function()
	setHovering()
	TweenService:Create(pageRight, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, Size = UDim2.new(0, 46, 0, 46)}):Play()
end)
pageRight.MouseLeave:Connect(function()
	setNotHovering()
	TweenService:Create(pageRight, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 40, 0, 40)}):Play()
end)

local itemGuis = {}
local selectedIndex = nil

for i = 1, 8 do
	local angle = math.rad((i - 1) * 45 - 90)
	local dist = (ringSize / 2) + (ringThickness / 2)
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Size = UDim2.new(0, 100, 0, 100)
	itemFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	itemFrame.Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist)
	itemFrame.BackgroundTransparency = 1
	itemFrame.Parent = container
	
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Parent = itemFrame
	icon.Image = ""
	icon.Parent = itemFrame
	
	local starIcon = Instance.new("TextLabel")
	starIcon.Size = UDim2.new(0, 18, 0, 18)
	starIcon.Position = UDim2.new(1, -18, 0, -5)
	starIcon.BackgroundTransparency = 1
	starIcon.Text = "⭐"
	starIcon.TextSize = 16
	starIcon.TextStrokeTransparency = 1
	starIcon.Visible = false
	starIcon.Parent = itemFrame
	
	itemGuis[i] = {Frame = itemFrame, Icon = icon, Star = starIcon, Angle = angle}
end

local function refreshMenuDisplay()
	local filtered = {}
	local favsAdded = 0
	local favSlots = {}
	local maxSlot = 0
	
	for _, emote in ipairs(allItems) do
		local matchSearch = string.find(string.lower(emote.name), string.lower(searchQuery), 1, true)
		if (matchSearch or searchQuery == "") and favItems[tostring(emote.id)] then
			local s = tonumber(favItems[tostring(emote.id)]) or 1
			favSlots[s] = emote
			if s > maxSlot then maxSlot = s end
		end
	end
	
	for i = 1, maxSlot do
		table.insert(filtered, favSlots[i] or false)
		favsAdded = favsAdded + 1
	end
	
	if searchQuery == "" and favsAdded > 0 then
		while #filtered % 8 ~= 0 do
			table.insert(filtered, false)
		end
	end
	
	for _, emote in ipairs(allItems) do
		local matchSearch = string.find(string.lower(emote.name), string.lower(searchQuery), 1, true)
		if (matchSearch or searchQuery == "") and not favItems[tostring(emote.id)] then
			table.insert(filtered, emote)
		end
	end
	
	local totalPages = math.max(1, math.ceil(#filtered / 8))
	if currentPage > totalPages then currentPage = totalPages end
	if currentPage < 1 then currentPage = 1 end
	
	pageLabel.Text = currentPage .. " / " .. totalPages
	
	currentDisplayedItems = {}
	local startIndex = (currentPage - 1) * 8
	
	for i = 1, 8 do
		local emote = filtered[startIndex + i]
		local itemGui = itemGuis[i]
		
		if type(emote) == "table" then
			itemGui.Icon.Image = "rbxthumb://type=" .. emote.type .. "&id=" .. emote.id .. "&w=150&h=150"
			itemGui.Star.Visible = (favItems[tostring(emote.id)] ~= nil)
			currentDisplayedItems[i] = emote
		else
			itemGui.Icon.Image = ""
			itemGui.Star.Visible = false
			currentDisplayedItems[i] = nil
		end
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text
	currentPage = 1
	refreshMenuDisplay()
end)

pageLeft.MouseButton1Click:Connect(function()
	if currentPage > 1 then
		currentPage = currentPage - 1
		refreshMenuDisplay()
	end
end)

pageRight.MouseButton1Click:Connect(function()
	currentPage = currentPage + 1
	refreshMenuDisplay()
end)

local function closeMenu()
	isMenuOpen = false
	searchBox:ReleaseFocus()
	clickBlocker.Visible = false
	pcall(function() game:GetService("ContextActionService"):UnbindAction("VT_EmoteHotkeys") end)
	local tween = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.95})
	TweenService:Create(ringStroke, TweenInfo.new(0.15), {Transparency = 1}):Play()
	TweenService:Create(blurEffect, TweenInfo.new(0.25), {Size = 0}):Play()
	
	tween:Play()
	tween.Completed:Connect(function()
		if not isMenuOpen then container.Visible = false end
	end)
end

local playEmoteIndex
local function openMenu()
	pcall(function()
		if isfile and isfile(favFileName) then
			local content = readfile(favFileName)
			if content and content ~= "" then
				favItems = HttpService:JSONDecode(content)
			end
		end
	end)
	isMenuOpen = true
	refreshMenuDisplay()
	
	uiScale.Scale = 0.5
	container.Visible = true
	clickBlocker.Visible = true
	centerText.Text = ""
	selectedIndex = nil
	TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.2}):Play()
	TweenService:Create(ringStroke, TweenInfo.new(0.2), {Transparency = 0.35}):Play()
	TweenService:Create(blurEffect, TweenInfo.new(0.25), {Size = 15}):Play()
	
	local CAS = game:GetService("ContextActionService")
	CAS:BindActionAtPriority("VT_EmoteHotkeys", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			local key = input.KeyCode
			local map = {
				[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2,
				[Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
				[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
				[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8
			}
			if map[key] then
				playEmoteIndex(map[key])
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value + 50,
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
	Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight)
end



local lastSelected = nil
local function updateSelection()
	if not isMenuOpen then return end
	
	local mouseLocation = UserInputService:GetMouseLocation()
	
	if isHoveringUI then
		if selectedIndex ~= nil then
			for i, item in ipairs(itemGuis) do
				TweenService:Create(item.Icon, TweenInfo.new(0.15), {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
				TweenService:Create(item.Star, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18), TextSize = 16}):Play()
			end
			centerText.Text = ""
			selectedIndex = nil
			lastSelected = nil
			TweenService:Create(pointerLine, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
		end
		return
	end
	
	local center = container.AbsolutePosition + container.AbsoluteSize / 2
	local dx = mouseLocation.X - center.X
	local dy = mouseLocation.Y - center.Y
	local distance = math.sqrt(dx*dx + dy*dy)
	
	if distance > (ringSize / 2) - 30 and distance < (ringSize / 2) + ringThickness + 20 then
		local angle = math.deg(math.atan2(dy, dx)) + 90
		if angle < 0 then angle = angle + 360 end
		
		local index = math.floor(((angle + 22.5) % 360) / 45) + 1
		
		if currentDisplayedItems[index] then
			if selectedIndex ~= index then
				selectedIndex = index
				
				for i, item in ipairs(itemGuis) do
					if i == selectedIndex then
						TweenService:Create(item.Icon, TweenInfo.new(0.15), {Size = UDim2.new(1.25, 0, 1.25, 0)}):Play()
						TweenService:Create(item.Star, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12), TextSize = 10}):Play()
						centerText.Text = currentDisplayedItems[i].name
						
						if lastSelected ~= selectedIndex then
							local clickSound = Instance.new("Sound")
							clickSound.SoundId = "rbxassetid://6895079853"
							clickSound.Volume = 0.5
							clickSound.Parent = container
							clickSound:Play()
							game.Debris:AddItem(clickSound, 1)
						end
					else
						TweenService:Create(item.Icon, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 1, 0)}):Play()
						TweenService:Create(item.Star, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18), TextSize = 16}):Play()
					end
				end
				lastSelected = selectedIndex
			end
		else
			if selectedIndex ~= nil then
				for i, item in ipairs(itemGuis) do
					TweenService:Create(item.Icon, TweenInfo.new(0.15), {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
					TweenService:Create(item.Star, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18), TextSize = 16}):Play()
				end
				centerText.Text = ""
				selectedIndex = nil
				lastSelected = nil
			end
		end
	else
		if selectedIndex ~= nil then
			for i, item in ipairs(itemGuis) do
				TweenService:Create(item.Icon, TweenInfo.new(0.15), {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
				TweenService:Create(item.Star, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18), TextSize = 16}):Play()
			end
			centerText.Text = ""
			selectedIndex = nil
			lastSelected = nil
		end
	end
end

playEmoteIndex = function(index)
	if index and currentDisplayedItems[index] then
		local emote = currentDisplayedItems[index]
		if emote.id then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
				
				if currentEmoteTrack then
					currentEmoteTrack:Stop()
				end
				
				local realAnimId = "rbxassetid://" .. tostring(emote.id)
				if emote.type == "Asset" then
					pcall(function()
						local objs = game:GetObjects(realAnimId)
						if objs and objs[1] and objs[1]:IsA("Animation") then
							realAnimId = objs[1].AnimationId
						end
					end)
				end
				
				local animation = Instance.new("Animation")
				animation.AnimationId = realAnimId
				local track = animator:LoadAnimation(animation)
				track.Priority = Enum.AnimationPriority.Action
				track:Play()
				currentEmoteTrack = track
				
				if currentMoveConnection then
					currentMoveConnection:Disconnect()
				end
				currentMoveConnection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
					if humanoid.MoveDirection.Magnitude > 0 then
						if currentEmoteTrack then
							currentEmoteTrack:Stop()
							currentEmoteTrack = nil
						end
					end
				end)
			end
		end
		closeMenu()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not sg.Parent then return end 
	
	if input.KeyCode == Enum.KeyCode.Period then
		if isMenuOpen then 
			searchBox:ReleaseFocus()
			closeMenu() 
		elseif not gameProcessed then 
			openMenu() 
		end
	end
	
	if isMenuOpen then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if isHoveringUI then return end
			playEmoteIndex(selectedIndex)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if isHoveringUI then return end
			
			if selectedIndex and currentDisplayedItems[selectedIndex] then
				local emote = currentDisplayedItems[selectedIndex]
				local eIdStr = tostring(emote.id)
				if favItems[eIdStr] then
					favItems[eIdStr] = nil
				else
					local usedSlots = {}
					for k, v in pairs(favItems) do
						if type(v) == "number" then usedSlots[v] = true end
					end
					local slot = 1
					while usedSlots[slot] do slot = slot + 1 end
					favItems[eIdStr] = slot
				end
				saveFavorites()
				refreshMenuDisplay()
			end
		end
	end
end)

RunService.RenderStepped:Connect(updateSelection)
end)
