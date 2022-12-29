--- Хейтеры, как вы меня заЫбали, идите нахЫй! ---
local version_str = '3.1'
local version_json = 1
print('Version script: '..version_str..', JSON: '..version_json)
script_author('kyrtion')
script_description('ВКонтакте: @kyrtion | Telegram: @kyrtion | Discord: kyrtion#7310. Специально для проекта Russia RP (Moscow)')
script_version(version_str)

--[[ История версии:
https://github.com/kyrtion/helperreport/version.md
]]

local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'

local imgui = require 'mimgui'
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local ffi = require 'ffi'
local memory = require 'memory'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local resX, resY = getScreenResolution()
local font = renderCreateFont('Console', resY >= 1080 and 12 or 10, 13)

function json(filePath)
	local f = {}
	function f:read()
		local f = io.open(filePath, "r+")
		local jsonInString = f:read("*a")
		f:close()
		local jsonTable = decodeJson(jsonInString)
		return jsonTable
	end
	function f:write(t)
		f = io.open(filePath, "w")
		f:write(encodeJson(t))
		f:flush()
		f:close()
	end
	return f
end

function sl(floatoffset_from_start_x, floatspacing)
	imgui.SameLine(floatoffset_from_start_x,floatspacing)
end

local update_state = false
local checkVerify = false
local lockVerify = false
local lockFailed = false
local newVersion = 'None'
local oldVersion = 'None'
local boolEnableAutoUpdate = true

local target = false
local keys = {
	["onfoot"] = {},
	["vehicle"] = {}
}

local cursorLock = false
local mainCursor = false
local reconCursor = false
local menuCursor = true
local keycapCursor = false

--! origin/main
local update_url = 'https://raw.githubusercontent.com/kyrtion/helper-report/main/version_hr.ini'
local update_path = getWorkingDirectory() .. '/update_hr.ini'
local script_vers = tostring(thisScript().version)
local script_url = 'https://github.com/kyrtion/helper-report/blob/main/helper-report-auto.lua?raw=true'
local script_path = thisScript().path

function join_argb(a, r, g, b)
	local argb = b  -- b
	argb = bit.bor(argb, bit.lshift(g, 8))  -- g
	argb = bit.bor(argb, bit.lshift(r, 16)) -- r
	argb = bit.bor(argb, bit.lshift(a, 24)) -- a
	return argb
end

function explode_argb(argb)
	local a = bit.band(bit.rshift(argb, 24), 0xFF)
	local r = bit.band(bit.rshift(argb, 16), 0xFF)
	local g = bit.band(bit.rshift(argb, 8), 0xFF)
	local b = bit.band(argb, 0xFF)
	return a, r, g, b
end

function intToHex(int)
    return '{'..string.sub(bit.tohex(int), 3, 8)..'}'
end

function alert(arg) sampAddChatMessage('[Helper-Report] {ffd0b0}'..arg, 0xffa86e) end

if not doesDirectoryExist('moonloader/config') then createDirectory('moonloader/config') end
if not doesDirectoryExist('moonloader/config/helper-report') then createDirectory ('moonloader/config/helper-report') end

local settingsJson = getWorkingDirectory()..'/config/helper-report/setting.json'
local settingsList = {}
local imguiList = {}

-- windows
local mainWindow = new.bool(false)
local menuWindow = new.bool(false)
local reconWindow = new.bool(false)
local keycapWindow = new.bool(false)

local selectPm = new.bool(true)
local statusSkip = new.bool(false)
local reportInput = new.char[140]('')
local reportInputAuthor = new.char[140]('')
local reportInputID = new.char[140]('')
local listReport = {}
local statusRecon = false
local selectedAZ = -1
local lockDefine = false
local lockWindow = false
local lockRecon = false
local playerIdRecon = -1
local closePop = false
local selectedIntButton = -1
local sizeButtonPopup = imgui.ImVec2(170,0)
local tab = new.int(1)
local reconPlayerTip, reconPlayerNick, reconId, blockId, target, statusReconButton = 'None', 'None', -1, -1, -1, false

local slist = {
	title = '',
	command = {},
	closePopup = false,
	startReconAuthor = false,
	startReconId = false,
	stopRecon = false
}

local sfist = {
	title = new.char[256](slist.title),
	command = {},
	closePopup = new.bool(slist.closePopup),
	startReconAuthor = new.bool(slist.startReconAuthor),
	startReconId = new.bool(slist.startReconId),
	stopRecon = new.bool(slist.stopRecon)
}

local intCountReport = 0
local boolCountReport = false
local new_text = ''
local old_text = ''
local commandText = ''
local commandImgui = new.char[1000](u8[[/pm @aid Приятной игры
/givegun @aid 24 228
/getstats @aid
/offban @anick 1 Уход от наказания]])
local newCommandImgui = commandImgui

local defaultJson = {
	version = version_json,
	settings = {
		closeReport = false,
		closeIfLeaved = false, -- кроме последний репорт
		hideAd = true,
		hideFloodInAdminChat = false,
		hideCursorIfRecon = true,
		autoSelectSms = true,
		showNewReport = true,
		otherPm = false,
	},
	settings2 = {
		answerAuthor = 			'Уважаемый игрок, сейчас попробую вам помочь.',
		answerAuthorId = 		'Уважаемый игрок, начинаю работу по вашей жалобе.',
		colorAdminChatNick = 	{r = 85, 	g = 255, 	b = 97, 	a = 255},
		colorAdminChatText = 	{r = 185, 	g = 255, 	b = 190, 	a = 255},
		colorAntiCheat = 		{r = 159, 	g = 0, 		b = 52, 	a = 255},
		colorOtherPrefixA = 	{r = 90, 	g = 90, 	b = 90, 	a = 255},
		colorPunishment = 		{r = 254, 	g = 57, 	b = 57, 	a = 255},
		colorPMNick = 			{r = 255, 	g = 223, 	b = 38, 	a = 255},
		colorPMText = 			{r = 255, 	g = 255, 	b = 185, 	a = 255},
		colorReportNick = 		{r = 255, 	g = 90,		b = 25,		a = 255},
		colorReportText = 		{r = 255, 	g = 205,	b = 185,	a = 255},
		boolAdminChatText = 	true,
		boolAdminChatNick = 	true,
		boolAntiCheat = 		true,
		boolOtherPrefixA = 		false,
		boolPunishment = 		false,
		boolPMText = 			true,
		boolPMNick = 			true,
		boolReportNick = 		true,
		boolReportText =		true,
		boolFormatAdminChat =	true,
		boolFullScreenAnswers =	false,
		textFormatAdminChat =	'[@prefix] @nick[@id]: @msg',
		positionX = 			20.0,
		positionY = 			450.0
	},
	button = {
		{
			title = 'Телепортировать',
			command = {
				'/pm @aid Телепортирую',
				'/goto @aid'
			},
			closePopup = true,
			startReconAuthor = false,
			startReconId = false,
			stopRecon = true
		},
		{
			title = 'Приятной игры',
			command = {
				'/pm @aid Спасибо, что вы играете на этом сервере. Приятной игры!'
			},
			closePopup = true,
			startReconAuthor = false,
			startReconId = false,
			stopRecon = false
		},
		{
			title = 'Жалоба в СГ',
			command = {
				'/pm @aid Оформляйте жалобу в свободной группе vk.соm/russia_sv'
			},
			closePopup = true,
			startReconAuthor = false,
			startReconId = false,
			stopRecon = false
		},
		{
			title = 'Передать в /a',
			command = {
				'/pm @aid Передам.',
				'/a [Репорт] @anick[@aid]: @msg'
			},
			closePopup = true,
			startReconAuthor = false,
			startReconId = false,
			stopRecon = false
		}
	}
}

if not doesFileExist(settingsJson) then
	local list = {
		version = defaultJson.version,
		settings = defaultJson.settings,
		settings2 = defaultJson.settings2,
		buttons = defaultJson.button
	}
	json(settingsJson):write(list)
end

local settingsList = json(settingsJson):read()

function save()
	json(settingsJson):write(settingsList)
	settingsList = json(settingsJson):read()
end

if settingsList.version == nil or settingsList.version ~= version_json then
	alert(tostring(settingsList.version)..', '..version_json)
	alert('В настройке не найдено новый часть, зарегистрировано по умолчанию в конфиге')
	settingsList.settings2 = defaultJson.settings2
	settingsList.version = defaultJson.version
	save()
end

local imguiList = {
	settings = {
		closeReport = new.bool(settingsList.settings.closeReport),
		closeIfLeaved = new.bool(settingsList.settings.closeIfLeaved), -- кроме последний репорт
		hideAd = new.bool(settingsList.settings.hideAd),
		hideFloodInAdminChat = new.bool(settingsList.settings.hideFloodInAdminChat),
		hideCursorIfRecon = new.bool(settingsList.settings.hideCursorIfRecon),
		autoSelectSms = new.bool(settingsList.settings.autoSelectSms),
		showNewReport = new.bool(settingsList.settings.showNewReport),
		otherPm = new.bool(settingsList.settings.otherPm)
	},
	settings2 = {
		answerAuthor = new.char[160](u8(settingsList.settings2.answerAuthor)),
		answerAuthorId = new.char[160](u8(settingsList.settings2.answerAuthorId)),
		--
		boolReportNick = new.bool(settingsList.settings2.boolReportNick),
		boolReportText = new.bool(settingsList.settings2.boolReportText),
		colorReportNick = new.float[4](settingsList.settings2.colorReportNick.r/255, settingsList.settings2.colorReportNick.g/255, settingsList.settings2.colorReportNick.b/255, settingsList.settings2.colorReportNick.a/255),
		colorReportText = new.float[4](settingsList.settings2.colorReportText.r/255, settingsList.settings2.colorReportText.g/255, settingsList.settings2.colorReportText.b/255, settingsList.settings2.colorReportText.a/255),
		--
		boolAdminChatNick = new.bool(settingsList.settings2.boolAdminChatNick),
		boolAdminChatText = new.bool(settingsList.settings2.boolAdminChatText),
		boolFormatAdminChat = new.bool(settingsList.settings2.boolFormatAdminChat),
		colorAdminChatNick = new.float[4](settingsList.settings2.colorAdminChatNick.r/255, settingsList.settings2.colorAdminChatNick.g/255, settingsList.settings2.colorAdminChatNick.b/255, settingsList.settings2.colorAdminChatNick.a/255),
		colorAdminChatText = new.float[4](settingsList.settings2.colorAdminChatText.r/255, settingsList.settings2.colorAdminChatText.g/255, settingsList.settings2.colorAdminChatText.b/255, settingsList.settings2.colorAdminChatText.a/255),
		textFormatAdminChat = new.char[255](settingsList.settings2.textFormatAdminChat),
		--
		boolPMNick = new.bool(settingsList.settings2.boolPMNick),
		boolPMText = new.bool(settingsList.settings2.boolPMText),
		colorPMNick = new.float[4](settingsList.settings2.colorPMNick.r/255, settingsList.settings2.colorPMNick.g/255, settingsList.settings2.colorPMNick.b/255, settingsList.settings2.colorPMNick.a/255),
		colorPMText = new.float[4](settingsList.settings2.colorPMText.r/255, settingsList.settings2.colorPMText.g/255, settingsList.settings2.colorPMText.b/255, settingsList.settings2.colorPMText.a/255),
		--
		boolPunishment = new.bool(settingsList.settings2.boolPunishment),
		colorPunishment = new.float[4](settingsList.settings2.colorPunishment.r/255, settingsList.settings2.colorPunishment.g/255, settingsList.settings2.colorPunishment.b/255, settingsList.settings2.colorPunishment.a/255),
		--
		boolAntiCheat = new.bool(settingsList.settings2.boolAntiCheat),
		colorAntiCheat = new.float[4](settingsList.settings2.colorAntiCheat.r/255, settingsList.settings2.colorAntiCheat.g/255, settingsList.settings2.colorAntiCheat.b/255, settingsList.settings2.colorAntiCheat.a/255),
		--
		boolOtherPrefixA = new.bool(settingsList.settings2.boolOtherPrefixA),
		colorOtherPrefixA = new.float[4](settingsList.settings2.colorOtherPrefixA.r/255, settingsList.settings2.colorOtherPrefixA.g/255, settingsList.settings2.colorOtherPrefixA.b/255, settingsList.settings2.colorOtherPrefixA.a/255),
		--
		boolFullScreenAnswers = new.bool(settingsList.settings2.boolFullScreenAnswers)
	}
}

local posX, posY = settingsList.settings2.positionX, settingsList.settings2.positionY

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	sW, sH = getScreenResolution()
	u32 = imgui.ColorConvertFloat4ToU32

	imgui.DarkTheme()
end)

local mainFrame = imgui.OnFrame(
	function() return mainWindow[0] and not isGamePaused() end,
	function(self)

		-- if not lockWindow then
		-- 	lockWindow = true
		-- 	self.HideCursor = true
		-- elseif not mainWindow[0] and lockWindow then
		-- 	self.HideCursor = true
		-- end
		-- if (isKeyJustPressed(0xA4) or isKeyJustPressed(0x59)) and (mainWindow[0] or reconWindow[0]) and not sampIsDialogActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
		-- 	self.HideCursor = not self.HideCursor
		-- end
		-- if not lockWindow and mainWindow[0] then
		-- 	lockWindow = true
		-- 	self.HideCursor = true
		-- end

		if not mainCursor then
			mainCursor = true
			self.HideCursor = true
		end

		local resX, resY = getScreenResolution()
		local sizeX, sizeY = 505, 160
		imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.Always)
		if imgui.Begin('##MainMain', mainWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoFocusOnAppearing) then
			if #listReport ~= 0 then
				if listReport[1].msg:find('(%d+)') and sampIsPlayerConnected(tonumber(listReport[1].msg:match('(%d+)'))) then
					local sId = listReport[1].msg:match('(%d+)')
					local sId = tonumber(sId)
					imgui.Columns(2, '##Author-Punisher', true)
					if imgui.Selectable(u8('Автор: '..listReport[1].nick..'['..listReport[1].id..']', false)) then
						imgui.OpenPopup('##MenuAuthor')
					end
					imgui.NextColumn()
					if sampIsPlayerConnected(sId) then
						if imgui.Selectable(u8('Пожаловал: '..sampGetPlayerNickname(sId)..'['..sId..']'), false) then
							imgui.OpenPopup('##MenuReported')
						end
					else
						imgui.Selectable('', false)
					end
				else
					imgui.Columns(1, '##Author-None', true)
					if imgui.Selectable(u8('Автор: '..listReport[1].nick..'['..listReport[1].id..']', false)) then
						imgui.OpenPopup('##MenuAuthor')
					end
				end
				imgui.Columns(1)
				imgui.Separator()
				imgui.TextS(u8(listReport[1].msg))

				imgui.SetCursorPosY(sizeY - 92)
				imgui.Separator()
				imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.824, 0.239, 0))
				imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.824, 0.239, 0))
				imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.824, 0.239, 0))
				imgui.Button('##best-button',imgui.ImVec2(1, 0))
				imgui.PopStyleColor(3)
				imgui.SameLine()
				if sampIsPlayerConnected(tonumber(listReport[1].id)) and listReport[1].nick == sampGetPlayerNickname(tonumber(listReport[1].id)) then
					imgui.Text(u8('Ваш ответ:')) imgui.SameLine() imgui.SetCursorPosX(90) imgui.TextColoredRGB('{00FF00}Автор в сети')
				elseif sampIsPlayerConnected(tonumber(listReport[1].id)) and listReport[1].nick ~= sampGetPlayerNickname(tonumber(listReport[1].id)) then
					imgui.Text(u8('Ваш ответ:')) imgui.SameLine() imgui.SetCursorPosX(90) imgui.TextColoredRGB('{FFFF00}Автор ник и ID не совпадает')
				elseif not sampIsPlayerConnected(tonumber(listReport[1].id)) then
					imgui.Text(u8('Ваш ответ:')) imgui.SameLine() imgui.SetCursorPosX(90) imgui.TextColoredRGB('{FFFF00}Автор не в сети')
				end
				imgui.SameLine()

				imgui.SetCursorPosX(306)
				if imgui.Button(u8'POS', imgui.ImVec2(42, 0)) then
					lua_thread.create(function ()
						sampSetCursorMode(3)
						checkCursor = true
						-- sampSetCursorMode(4)
						alert('Нажмите "SPACE" чтобы сохранить позицию')
						while checkCursor do
							local cX, cY = getCursorPos()
							posX, posY = cX, cY
							if isKeyDown(32) then -- 32 = Space
								settingsList.settings2.positionX, settingsList.settings2.positionY = posX, posY
								checkCursor = false
								-- showCursor(false)
								sampSetCursorMode(0)
								save()
								alert('Сохранено')
							end
							wait(0)
						end
					end)
				end
				imgui.SameLine()

				if selectPm[0] then
					if imgui.Button(u8'PM', imgui.ImVec2(42, 0)) then
						selectPm[0] = not selectPm[0]
					end
				else
					imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.824, 0.239, 1.00))
					imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.824, 0.239, 0.90))
					imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.824, 0.239, 0.80))
					imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0, 0, 0, 1))
					if imgui.Button(u8'SMS', imgui.ImVec2(42, 0)) then
						selectPm[0] = not selectPm[0]
					end
					imgui.PopStyleColor(4)
				end

				imgui.SameLine()
				if statusSkip[0] then
					imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.824, 0.239, 1.00))
					imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.824, 0.239, 0.90))
					imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.824, 0.239, 0.80))
					imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0, 0, 0, 1))
					if imgui.Button(u8'SKIP', imgui.ImVec2(42, 0)) then
						statusSkip[0] = not statusSkip[0]
					end
					imgui.PopStyleColor(4)
				else
					if imgui.Button(u8'SKIP', imgui.ImVec2(42, 0)) then
						statusSkip[0] = not statusSkip[0]
					end
				end

				imgui.SameLine()
				imgui.SetCursorPosX(sizeX-57)
				imgui.Text(get_timer(listReport[1].timer))

				imgui.PushItemWidth(sizeX - 10)
				if imgui.InputText(u8'##reportInput', reportInput, sizeof(reportInput), imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.None) then
					if #u8:decode(str(reportInput)) ~= 0 then
						print('{FF0000}Enter ['..(selectPm[0] and 'PM' or 'SMS')..']: '..u8:decode(str(reportInput)))
						sampSendChat('/'..(selectPm[0] and 'pm' or 'sms')..' '..listReport[1].id..' '..u8:decode(str(reportInput)))
						reportInput = new.char[256]('')
						if settingsList.settings.autoSelectSms then selectPm[0] = false end
						if statusSkip[0] then removeReport(1, true) end
					end
				end
				imgui.PopItemWidth()
				if #listReport ~= 0 then
					imgui.SetCursorPosY(sizeY - 29)
					if sampIsPlayerConnected(listReport[1].id) and sampGetPlayerNickname(listReport[1].id) == listReport[1].nick then
						if imgui.Button(u8'RE: Автор', imgui.ImVec2(120, 0)) then
							if settingsList.settings.hideCursorIfRecon then sampSetCursorMode(0) end
							if settingsList.settings.autoSelectSms then selectPm[0] = false end
							alert('Вы наблюдаете на '..sampGetPlayerNickname(listReport[1].id)..'['..listReport[1].id..']')
							sampSendChat('/re '..listReport[1].id)
							if not listReport[1].recon then
								listReport[1].recon = true
								lua_thread.create(function()
									if #settingsList.settings2.answerAuthor ~= 0 then
										wait(1050)
										local messa = '/pm '..listReport[1].id..' '..settingsList.settings2.answerAuthor
										sampSendChat(messa)
									end
								end)
							end
						end
					else
						imgui.InvisibleButton('', imgui.ImVec2(120, 0))
					end
					imgui.SameLine()
					local reId = listReport[1].msg:match('(%d+)') or -1
					if sampIsPlayerConnected(reId) and not sampIsPlayerNpc(reId) then
						if imgui.Button(u8'RE: ID', imgui.ImVec2(120, 0)) then
							if #listReport ~= 0 and #listReport[1].msg ~= 0 and listReport[1].msg:find('(%d+)') then
								if sampIsPlayerConnected(reId) and not sampIsPlayerNpc(reId) then
									if settingsList.settings.autoSelectSms then selectPm[0] = false end
									if settingsList.settings.hideCursorIfRecon then sampSetCursorMode(0) end
									alert('Вы наблюдаете на '..sampGetPlayerNickname(reId)..'['..reId..']')
									sampSendChat('/re '..reId, -1)
									if not listReport[1].recon then
										listReport[1].recon = true
										lua_thread.create(function()
											if #settingsList.settings2.answerAuthorId ~= 0 then
												wait(1050)
												local messa = '/pm '..listReport[1].id..' '..settingsList.settings2.answerAuthorId
												sampSendChat(messa)
											end
										end)
									end
								else
									alert('Пожалованный игрок не в сети!')
								end
							end
						end
					else
						imgui.InvisibleButton('', imgui.ImVec2(120, 0))
					end
					imgui.SameLine()
					if imgui.Button(u8'Ответы', imgui.ImVec2(120, 0)) then
						if not settingsList.settings2.boolFullScreenAnswers then imgui.OpenPopup('##AnswersAuthor')
						else imgui.OpenPopup(u8'Ответы') end
					end
					imgui.SameLine()
					if #u8:decode(str(reportInput)) == 0 or u8:decode(str(reportInput)):find('^%s+$') then
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
						if imgui.Button(u8'Закрыть', imgui.ImVec2(120, 0)) then
							print('{F2B0B0}Пропущено: '..u8:decode(str(reportInput)))
							reportInput = new.char[256]('')
							removeReport(1, true)
						end 
						imgui.PopStyleColor(3)
					else
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
						if imgui.Button(u8'Ответить', imgui.ImVec2(120, 0)) then
							if sampIsPlayerConnected(tonumber(listReport[1].id)) then
								if sampGetPlayerNickname(tonumber(listReport[1].id)) == listReport[1].nick then
									if #u8:decode(str(reportInput)) ~= 0 and #listReport ~= 0 then
										if not listReport[1].recon then listReport[1].recon = true end
										print('{FF0000}Enter ['..(selectPm[0] and 'PM' or 'SMS')..']: '..u8:decode(str(reportInput)))
										sampSendChat('/'..(selectPm[0] and 'pm' or 'sms')..' '..listReport[1].id..' '..u8:decode(str(reportInput)))
										reportInput = new.char[256]('')
										selectPm[0] = false
										if statusSkip[0] then removeReport(1, true) end
									else
										alert('Вы не указали ответ!')
									end
								else
									alert('Автор ник и ID не совпадает!')
									--! DEBUG start
									-- reportInput = new.char[256]('')
									-- if settingsList.settings.autoSelectSms then selectPm[0] = false end
									-- if statusSkip[0] then removeReport(1, true) --[[goto skip]] end
									--! DEBUG end
								end
							else
								alert('Автор не в сети!')
							end
						end 
						imgui.PopStyleColor(3)
					end

					----! POPUP
						
					if imgui.BeginPopup('##AnswersAuthor') then
						imgui.Text(u8('Удержите "левый Ctrl" и нажмите серые кнопки, если\nсделал то после ответа сразу скипает репорт'))
						for i=1, #settingsList.buttons do
							local statusS = false
							if isKeyDown(0xA2) then statusS = true else statusS = false end
							local findPm = false
							for n=1, #settingsList.buttons[i].command do
								if (settingsList.buttons[i].command[n]):find('^%/pm') then
									findPm = true
									break
								end
							end
							if statusS then
								imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.34, 0.42, 0.51, 0.8))
								imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.34, 0.42, 0.51, 0.7))
								imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.34, 0.42, 0.51, 0.6))
							end
							if imgui.Button(u8(settingsList.buttons[i].title..(findPm and ' [PM]' or '')), sizeButtonPopup) then
								if not listReport[1].recon then listReport[1].recon = true end
								lua_thread.create(function()
									local status = statusS
									local authorId = listReport[1].id
									local authorNick = listReport[1].nick
									local messageReport = listReport[1].msg
									local reportId = tonumber(listReport[1].msg:match('(%d+)')) or -1
									local reportNick = reportId ~= -1 and reportId or -1
									if settingsList.buttons[i].startReconAuthor then sampSendChat('/re '..authorId); wait(1050) end
									if settingsList.buttons[i].startReconId then
										if reportId ~= -1 then
											if sampIsPlayerConnected(reportId) then
												sampSendChat('/re '..reportId)
												wait(1050)
											else
												alert('Пожалованный игрок не в сети!')
											end
										else
											alert('В сообщение не указано ID!')
										end
									end
									if settingsList.buttons[i].stopRecon and statusRecon then sampSendChat('/re off'); wait(1050) end
									for n=1, #settingsList.buttons[i].command do
										local msg = (((((settingsList.buttons[i].command[n]):gsub('@aid', authorId)):gsub('@anick', authorNick)):gsub('@msg', messageReport)):gsub('@rid', reportId)):gsub('@rnick', reportNick)
										sampSendChat(msg)
										if n ~= #settingsList.buttons[i].command then wait(1100) end
									end
									if status then removeReport(1, true) end
								end)
								if settingsList.settings.autoSelectSms then selectPm[0] = false end
								if settingsList.buttons[i].closePopup then imgui.CloseCurrentPopup() end
							end
							if statusS then
								imgui.PopStyleColor(3)
							end
							if i % 3 ~= 0 then imgui.SameLine() end
							findPm = false
						end
					end
					if imgui.BeginPopupModal(u8'Ответы', false, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
						imgui.Text(u8('Удержите "левый Ctrl" и нажмите серые кнопки, если сделал то после ответа сразу скипает репорт'))
						
						for i=1, #settingsList.buttons do
							local statusS = false
							if isKeyDown(0xA2) then statusS = true else statusS = false end
							local findPm = false
							for n=1, #settingsList.buttons[i].command do
								if (settingsList.buttons[i].command[n]):find('^%/pm') then
									findPm = true
									break
								end
							end
							if statusS then
								imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.34, 0.42, 0.51, 0.8))
								imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.34, 0.42, 0.51, 0.7))
								imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.34, 0.42, 0.51, 0.6))
							end

							if imgui.Button(u8(settingsList.buttons[i].title..(findPm and ' [PM]' or '')), sizeButtonPopup) then
								if not listReport[1].recon then listReport[1].recon = true end
								lua_thread.create(function()
									local status = statusS
									local authorId = listReport[1].id
									local authorNick = listReport[1].nick
									local messageReport = listReport[1].msg
									local reportId = tonumber(listReport[1].msg:match('(%d+)')) or -1
									local reportNick = reportId ~= -1 and reportId or -1
									if settingsList.buttons[i].startReconAuthor then sampSendChat('/re '..authorId); wait(1050) end
									if settingsList.buttons[i].startReconId then
										if reportId ~= -1 then
											if sampIsPlayerConnected(reportId) then
												sampSendChat('/re '..reportId)
												wait(1050)
											else
												alert('Пожалованный игрок не в сети!')
											end
										else
											alert('В сообщение не указано ID!')
										end
									end
									if settingsList.buttons[i].stopRecon and statusRecon then sampSendChat('/re off'); wait(1050) end
									for n=1, #settingsList.buttons[i].command do
										local msg = (((((settingsList.buttons[i].command[n]):gsub('@aid', authorId)):gsub('@anick', authorNick)):gsub('@msg', messageReport)):gsub('@rid', reportId)):gsub('@rnick', reportNick)
										sampSendChat(msg)
										if n ~= #settingsList.buttons[i].command then wait(1100) end
									end
									if status then removeReport(1, true) end
								end)
								if settingsList.settings.autoSelectSms then selectPm[0] = false end
								if settingsList.buttons[i].closePopup then imgui.CloseCurrentPopup() end
							end
							if statusS then
								imgui.PopStyleColor(3)
							end
							if i % 5 ~= 0 and i ~= #settingsList.buttons then imgui.SameLine() end
							findPm = false
						end
						
						for n=1, 5 do
							imgui.SetCursorPos(imgui.ImVec2(3,3))
							imgui.SameLine()
							imgui.InvisibleButton('f##bb'..n, imgui.ImVec2(0.01,0.01))
						end
						imgui.Separator()
						if imgui.Button(u8'Закрыть', imgui.ImVec2(imgui.GetWindowSize().x-10, 0)) then
							imgui.CloseCurrentPopup()
						end
						if isKeyDown(0x1B) then
							imgui.CloseCurrentPopup()
						end
					end
					
					
					-- end
					if imgui.BeginPopup('##MenuAuthor', imgui.WindowFlags.NoMove) then
						local oneSize = imgui.ImVec2(160,0)
						local twoSize = imgui.ImVec2(77.6,0)
						local ConId = tonumber(listReport[1].id)
						imgui.Text('ID: '..listReport[1].id..'  |  Nick: '..listReport[1].nick)
						imgui.Separator()
						if imgui.Button(u8'NICK') then
							alert('Скопировано ник: '..listReport[1].nick)
							setClipboardText(listReport[1].nick)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'ID') then
							alert('Скопировано ID: '..listReport[1].id)
							setClipboardText(listReport[1].id)
							imgui.CloseCurrentPopup()
						end
						if sampIsPlayerConnected(tonumber(listReport[1].id)) and sampGetPlayerNickname(tonumber(listReport[1].id)) == listReport[1].nick then
							imgui.SameLine()
							if imgui.Button(u8'GETSTATS') then
								sampSendChat('/getstats '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'IWEP') then
								sampSendChat('/iwep '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end

							imgui.Separator()

							if imgui.Button(u8'GOTO') then
								lua_thread.create(function()
									if statusRecon then
										sampSetCursorMode(0)
										sampSendChat('/re off')
										wait(1000)
									end
									sampSendChat('/goto '..listReport[1].id)
								end)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'GETHERE') then
								lua_thread.create(function()
									if statusRecon then
										sampSetCursorMode(0)
										sampSendChat('/re off')
										wait(1000)
									end
									sampSendChat('/gethere '..listReport[1].id)
								end)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'SPAWN') then
								sampSendChat('/sp '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'SLAP') then
								sampSendChat('/slap '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end

							if imgui.Button(u8'FREEZE') then
								sampSendChat('/freeze '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'UNFREEZE') then
								sampSendChat('/unfreeze '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'GIVEGUN') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/givegun '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.Separator()

							if imgui.Button(u8'MUTE') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/mute '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'RMUTE') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/rmute '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'JAIL') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/jail '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'UNJAIL') then
								sampSendChat('/unjail '..listReport[1].id)
								imgui.CloseCurrentPopup()
							end

							if imgui.Button(u8'UVAL') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/uval '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'BAN') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/ban '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'SBAN') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/sban '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'KICK') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/kick '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'SKICK') then
								sampSetChatInputEnabled(true)
								sampSetChatInputText('/skick '..listReport[1].id..' ')
								imgui.CloseCurrentPopup()
							end
							imgui.Separator()
							if imgui.Button(u8'Наказать за репорт') then
								imgui.OpenPopup('##AuthorReportPunish')
							end
							if closePop then
								closePop = false
								imgui.CloseCurrentPopup()
							end
						end
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
						if imgui.Button(u8'Наказать за уход от наказания') then
							sampSendChat('/offban '..listReport[1].nick..' 1 Left from punishment')
							imgui.CloseCurrentPopup()
						end
						imgui.PopStyleColor(3)
					end
					if imgui.BeginPopup('##MenuReported', imgui.WindowFlags.NoMove) and sampIsPlayerConnected(tonumber(listReport[1].msg:match('(%d+)'))) then
						local oneSize = imgui.ImVec2(160,0)
						local twoSize = imgui.ImVec2(77.6,0)
						local ConId = tonumber(listReport[1].msg:match('(%d+)'))
						imgui.Text(('ID: '..ConId..'  |  Nick: '..sampGetPlayerNickname(ConId)))
						imgui.Separator()
						if imgui.Button(u8'NICK') then
							alert('Скопировано ник: '..sampGetPlayerNickname(ConId))
							setClipboardText(sampGetPlayerNickname(ConId))
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'ID') then
							alert('Скопировано ID: '..ConId)
							setClipboardText(ConId)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'GETSTATS') then
							sampSendChat('/getstats '..ConId)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'IWEP') then
							sampSendChat('/iwep '..ConId)
							imgui.CloseCurrentPopup()
						end

						imgui.Separator()

						if imgui.Button(u8'GOTO') then
							lua_thread.create(function()
								if statusRecon then
									sampSetCursorMode(0)
									sampSendChat('/re off')
									wait(1000)
								end
								sampSendChat('/goto '..ConId)
							end)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'GETHERE') then
							lua_thread.create(function()
								if statusRecon then
									sampSetCursorMode(0)
									sampSendChat('/re off')
									wait(1000)
								end
								sampSendChat('/gethere '..ConId)
							end)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'SPAWN') then
							sampSendChat('/sp '..ConId)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'SLAP') then
							sampSendChat('/slap '..ConId)
							imgui.CloseCurrentPopup()
						end

						if imgui.Button(u8'FREEZE') then
							sampSendChat('/freeze '..ConId)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'UNFREEZE') then
							sampSendChat('/unfreeze '..ConId)
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'GIVEGUN') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/givegun '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.Separator()

						if imgui.Button(u8'MUTE') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/mute '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'RMUTE') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/rmute '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'JAIL') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/jail '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'UNJAIL') then
							sampSendChat('/unjail '..ConId)
							imgui.CloseCurrentPopup()
						end

						if imgui.Button(u8'UVAL') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/uval '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'BAN') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/ban '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'SBAN') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/sban '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'KICK') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/kick '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(u8'SKICK') then
							sampSetChatInputEnabled(true)
							sampSetChatInputText('/skick '..ConId..' ')
							imgui.CloseCurrentPopup()
						end
					end
					if imgui.BeginPopup('##AuthorReportPunish', imgui.WindowFlags.NoMove) then
						local id = tonumber(listReport[1].id)
						imgui.Text(('ID: '..id..'  |  Nick: '..(sampGetPlayerNickname(id) or listReport[1].nick..' [Не в сети]')))
						if sampIsPlayerConnected(tonumber(listReport[1].id)) then
							if imgui.Button(u8'Оффтоп') then
								sampSendChat('/rmute '..id..' 15 Оффтоп')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Капс') then
								sampSendChat('/rmute '..id..' 10 CapsLock')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Флуд') then
								sampSendChat('/rmute '..id..' 10 Flood')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Оскорбление') then
								sampSendChat('/rmute '..id..' 30 Оскорбление администрации')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Неадекватное поведение') then
								sampSendChat('/rmute '..id..' 30 Неадекватное поведение')
								closePop = true
								imgui.CloseCurrentPopup()
							end

							if imgui.Button(u8'Клевета') then
								sampSendChat('/rmute '..id..' 10 Клевета администрации')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Обман') then
								sampSendChat('/rmute '..id..' 10 Обман администрации')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Упом.родных') then
								sampSendChat('/rmute '..id..' 30 Упоминание родных')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Оск.родных') then
								sampSendChat('/rmute '..id..' 60 Оскорбление родных')
								closePop = true
								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button(u8'Оск.проекта') then
								sampSendChat('/rmute '..id..' 60 Оскорбление проекта')
								closePop = true
								imgui.CloseCurrentPopup()
							end
						end
					end
				end
			else
				if imgui.InvisibleButton('##che',imgui.ImVec2(sizeX-10, sizeY-10)) then
					sampSendChat('/define')
					lockDefine = true
				end
				imgui.SetCursorPosY(sizeY/2 - 18)
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 0.1))
				imgui.CenterText(u8'Нажмите "P" чтобы скрыть окно')
				imgui.CenterText(u8'Для обновление нажмите меня')
				imgui.PopStyleColor(1)
			end
		imgui.End()
		end
	end
)

local menuFrame = imgui.OnFrame(
    function() return menuWindow[0] and not isGamePaused() end,
	function(self)

		if not menuCursor then
			menuCursor = true
			self.HideCursor = false
		end

		local resX, resY = getScreenResolution()
		local sizeX, sizeY = 650, 419
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
		if imgui.Begin(u8'Меню | Helper-Report '..thisScript().version, menuWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove) then
			if imgui.Button(u8'Настройки', imgui.ImVec2(140,60)) then tab[0] = 1 end
			if imgui.Button(u8'Чаты', imgui.ImVec2(140,60)) then tab[0] = 2 end
			if imgui.Button(u8'Ответы', imgui.ImVec2(140,60)) then tab[0] = 3 end
			imgui.SameLine()

			imgui.SetCursorPosY(29)
			if imgui.BeginChild('##menu-begin', imgui.ImVec2(sizeX-155, sizeY-34), true) then
				if tab[0] == 1 then
					imgui.SetCursorPosY(10)
					imgui.CenterText(u8'Настройки')
					imgui.SetCursorPosY(34)
					imgui.Separator()
					imgui.PushItemWidth(475)
					imgui.Text(u8'Ответ через PM при рекон автора:')
					if imgui.InputText(u8'##answerAuthor', imguiList.settings2.answerAuthor, sizeof(imguiList.settings2.answerAuthor)) then
						settingsList.settings2.answerAuthor = u8:decode(str(imguiList.settings2.answerAuthor))
						-- alert(settingsList.settings2.answerAuthor) -- debug
						save()
					end
					imgui.Text(u8'Ответ через PM при рекон пожалованного:')
					if imgui.InputText(u8'##answerAuthorId', imguiList.settings2.answerAuthorId, sizeof(imguiList.settings2.answerAuthorId)) then
						settingsList.settings2.answerAuthorId = u8:decode(str(imguiList.settings2.answerAuthorId))
						-- alert(settingsList.settings2.answerAuthorId) -- debug
						save()
					end
					imgui.TextDisabled(u8'Вы можете оставить пустым, если не хотите отправлять PM при рекон')
					imgui.PopItemWidth()
					imgui.Separator()
					if imgui.Checkbox(u8'Полный экран список ответов', imguiList.settings2.boolFullScreenAnswers) then
						settingsList.settings2.boolFullScreenAnswers = imguiList.settings2.boolFullScreenAnswers[0]
						save()
					end

					if imgui.Checkbox(u8'После первого ответа скипать жалобу (жёлтая кнопка)', imguiList.settings.closeReport) then
						settingsList.settings.closeReport = imguiList.settings.closeReport[0]
						save()
					end
					if imgui.Checkbox(u8'Переходить на SMS после первого ответа (жёлтая кнопка)', imguiList.settings.autoSelectSms) then
						settingsList.settings.autoSelectSms = imguiList.settings.autoSelectSms[0]
						save()
					end
					if imgui.Checkbox(u8'Если игрок вышел с игры скипать жалобу (кроме последней)', imguiList.settings.closeIfLeaved) then
						settingsList.settings.closeIfLeaved = imguiList.settings.closeIfLeaved[0]
						save()
					end
					if imgui.Checkbox(u8'Скрыть рекламы (в том числе /donaterub и /adonate)', imguiList.settings.hideAd) then
						settingsList.settings.hideAd = imguiList.settings.hideAd[0]
						save()
					end
					if imgui.Checkbox(u8'Скрыть последнее повтроное сообщение в админ-чат (/a)', imguiList.settings.hideFloodInAdminChat) then
						settingsList.settings.hideFloodInAdminChat = imguiList.settings.hideFloodInAdminChat[0]
						save()
					end
					if imgui.Checkbox(u8'Скрыть курсор при рекон (/re)', imguiList.settings.hideCursorIfRecon) then
						settingsList.settings.hideCursorIfRecon = imguiList.settings.hideCursorIfRecon[0]
						save()
					end
					if imgui.Checkbox(u8'Показывать окно если появится новый репорт', imguiList.settings.showNewReport) then
						settingsList.settings.showNewReport = imguiList.settings.showNewReport[0]
						save()
					end
					if imgui.Checkbox(u8'Скрыть другие ответы администратора (кроме себя)', imguiList.settings.otherPm) then
						settingsList.settings.otherPm = imguiList.settings.otherPm[0]
						save()
					end
				elseif tab[0] == 2 then
					imgui.SetCursorPosY(10)
					imgui.CenterText(u8'Чаты')
					imgui.SetCursorPosY(34)
					imgui.Separator()
					imgui.Text(u8('Формат админский чат: '..((u8:decode(str(imguiList.settings2.textFormatAdminChat))):gsub('@prefix', 'Руководитель'):gsub('@nick', sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))):gsub('@id', select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))):gsub('@msg', 'Hello world!'))))
					if imgui.Button('Restore##textFormatAdminChat') then
						settingsList.settings2.textFormatAdminChat = defaultJson.settings2.textFormatAdminChat
						imguiList.settings2.textFormatAdminChat = new.char[255](settingsList.settings2.textFormatAdminChat)
						save()
					end imgui.SameLine()
					imgui.PushItemWidth(426)
					if imgui.InputText(u8'##textFormatAdminChat', imguiList.settings2.textFormatAdminChat, sizeof(imguiList.settings2.textFormatAdminChat)) then
						settingsList.settings2.textFormatAdminChat = u8:decode(str(imguiList.settings2.textFormatAdminChat))
						save()
					end
					imgui.PopItemWidth()
					imgui.Separator()

					imgui.PushItemWidth(25)
					if imgui.Checkbox('##boolReportNick', imguiList.settings2.boolReportNick) then settingsList.settings2.boolReportNick = imguiList.settings2.boolReportNick[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolReportNick') then settingsList.settings2.colorReportNick = defaultJson.settings2.colorReportNick imguiList.settings2.colorReportNick = new.float[4](settingsList.settings2.colorReportNick.r/255, settingsList.settings2.colorReportNick.g/255, settingsList.settings2.colorReportNick.b/255, settingsList.settings2.colorReportNick.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[Репорт] В начале', imguiList.settings2.colorReportNick, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorReportNick = {r = imguiList.settings2.colorReportNick[0]*255, g = imguiList.settings2.colorReportNick[1]*255, b = imguiList.settings2.colorReportNick[2]*255, a = 255} save() end
					----
					if imgui.Checkbox('##boolReportText', imguiList.settings2.boolReportText) then settingsList.settings2.boolReportText = imguiList.settings2.boolReportText[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolReportText') then settingsList.settings2.colorReportText = defaultJson.settings2.colorReportText imguiList.settings2.colorReportText = new.float[4](settingsList.settings2.colorReportText.r/255, settingsList.settings2.colorReportText.g/255, settingsList.settings2.colorReportText.b/255, settingsList.settings2.colorReportText.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[Репорт] После ника', imguiList.settings2.colorReportText, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorReportText = {r = imguiList.settings2.colorReportText[0]*255, g = imguiList.settings2.colorReportText[1]*255, b = imguiList.settings2.colorReportText[2]*255, a = 255} save() end


					if imgui.Checkbox('##boolPMNick', imguiList.settings2.boolPMNick) then settingsList.settings2.boolPMNick = imguiList.settings2.boolPMNick[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolPMNick') then settingsList.settings2.colorPMNick = defaultJson.settings2.colorPMNick imguiList.settings2.colorPMNick = new.float[4](settingsList.settings2.colorPMNick.r/255, settingsList.settings2.colorPMNick.g/255, settingsList.settings2.colorPMNick.b/255, settingsList.settings2.colorPMNick.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[PM] В начале', imguiList.settings2.colorPMNick, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorPMNick = {r = imguiList.settings2.colorPMNick[0]*255, g = imguiList.settings2.colorPMNick[1]*255, b = imguiList.settings2.colorPMNick[2]*255, a = 255} save() end
					----
					if imgui.Checkbox('##boolPMText', imguiList.settings2.boolPMText) then settingsList.settings2.boolPMText = imguiList.settings2.boolPMText[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolPMText') then settingsList.settings2.colorPMText = defaultJson.settings2.colorPMText imguiList.settings2.colorPMText = new.float[4](settingsList.settings2.colorPMText.r/255, settingsList.settings2.colorPMText.g/255, settingsList.settings2.colorPMText.b/255, settingsList.settings2.colorPMText.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[PM] После ника', imguiList.settings2.colorPMText, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorPMText = {r = imguiList.settings2.colorPMText[0]*255, g = imguiList.settings2.colorPMText[1]*255, b = imguiList.settings2.colorPMText[2]*255, a = 255} save() end


					if imgui.Checkbox('##boolAdminChatNick', imguiList.settings2.boolAdminChatNick) then settingsList.settings2.boolAdminChatNick = imguiList.settings2.boolAdminChatNick[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolAdminChatNick') then settingsList.settings2.colorAdminChatNick = defaultJson.settings2.colorAdminChatNick imguiList.settings2.colorAdminChatNick = new.float[4](settingsList.settings2.colorAdminChatNick.r/255, settingsList.settings2.colorAdminChatNick.g/255, settingsList.settings2.colorAdminChatNick.b/255, settingsList.settings2.colorAdminChatNick.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[Админ-чат] В начале', imguiList.settings2.colorAdminChatNick, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorAdminChatNick = {r = imguiList.settings2.colorAdminChatNick[0]*255, g = imguiList.settings2.colorAdminChatNick[1]*255, b = imguiList.settings2.colorAdminChatNick[2]*255, a = 255} save() end
					----
					if imgui.Checkbox('##boolAdminChatText', imguiList.settings2.boolAdminChatText) then settingsList.settings2.boolAdminChatText = imguiList.settings2.boolAdminChatText[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolAdminChatText') then settingsList.settings2.colorAdminChatText = defaultJson.settings2.colorAdminChatText imguiList.settings2.colorAdminChatText = new.float[4](settingsList.settings2.colorAdminChatText.r/255, settingsList.settings2.colorAdminChatText.g/255, settingsList.settings2.colorAdminChatText.b/255, settingsList.settings2.colorAdminChatText.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'[Админ-чат] После ника', imguiList.settings2.colorAdminChatText, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorAdminChatText = {r = imguiList.settings2.colorAdminChatText[0]*255, g = imguiList.settings2.colorAdminChatText[1]*255, b = imguiList.settings2.colorAdminChatText[2]*255, a = 255} save() end


					if imgui.Checkbox('##boolAntiCheat', imguiList.settings2.boolAntiCheat) then settingsList.settings2.boolAntiCheat = imguiList.settings2.boolAntiCheat[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolAntiCheat') then settingsList.settings2.colorAntiCheat = defaultJson.settings2.colorAntiCheat imguiList.settings2.colorAntiCheat = new.float[4](settingsList.settings2.colorAntiCheat.r/255, settingsList.settings2.colorAntiCheat.g/255, settingsList.settings2.colorAntiCheat.b/255, settingsList.settings2.colorAntiCheat.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'Античит', imguiList.settings2.colorAntiCheat, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorAntiCheat = {r = imguiList.settings2.colorAntiCheat[0]*255, g = imguiList.settings2.colorAntiCheat[1]*255, b = imguiList.settings2.colorAntiCheat[2]*255, a = 255} save() end
					----
					if imgui.Checkbox('##boolPunishment', imguiList.settings2.boolPunishment) then settingsList.settings2.boolPunishment = imguiList.settings2.boolPunishment[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolPunishment') then settingsList.settings2.colorPunishment = defaultJson.settings2.colorPunishment imguiList.settings2.colorPunishment = new.float[4](settingsList.settings2.colorPunishment.r/255, settingsList.settings2.colorPunishment.g/255, settingsList.settings2.colorPunishment.b/255, settingsList.settings2.colorPunishment.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'Действие адм', imguiList.settings2.colorPunishment, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorPunishment = {r = imguiList.settings2.colorPunishment[0]*255, g = imguiList.settings2.colorPunishment[1]*255, b = imguiList.settings2.colorPunishment[2]*255, a = 255} save() end
					----
					if imgui.Checkbox('##boolOtherPrefixA', imguiList.settings2.boolOtherPrefixA) then settingsList.settings2.boolOtherPrefixA = imguiList.settings2.boolOtherPrefixA[0] save() end imgui.SameLine()
					if imgui.Button('Restore##boolOtherPrefixA') then settingsList.settings2.colorOtherPrefixA = defaultJson.settings2.colorOtherPrefixA imguiList.settings2.colorOtherPrefixA = new.float[4](settingsList.settings2.colorOtherPrefixA.r/255, settingsList.settings2.colorOtherPrefixA.g/255, settingsList.settings2.colorOtherPrefixA.b/255, settingsList.settings2.colorOtherPrefixA.a/255) save() end imgui.SameLine()
					if imgui.ColorEdit3(u8'Прочее действие адм с префиксом [A]', imguiList.settings2.colorOtherPrefixA, imgui.ColorEditFlags.NoAlpha + imgui.ColorEditFlags.NoInputs) then settingsList.settings2.colorOtherPrefixA = {r = imguiList.settings2.colorOtherPrefixA[0]*255, g = imguiList.settings2.colorOtherPrefixA[1]*255, b = imguiList.settings2.colorOtherPrefixA[2]*255, a = 255} save() end
					imgui.PopItemWidth()

				elseif tab[0] == 3 then
					imgui.SetCursorPosY(10)
					imgui.CenterText(u8'Ответы')
					imgui.SetCursorPos(imgui.ImVec2(sizeX-217,5))
					if imgui.Button(u8'Создать') then
						commandText = ''
						commandImgui = newCommandImgui
						sfist = {
							title = new.char[256](slist.title),
							command = {},
							closePopup = new.bool(slist.closePopup),
							startReconAuthor = new.bool(slist.startReconAuthor),
							startReconId = new.bool(slist.startReconId),
							stopRecon = new.bool(slist.stopRecon)
						}
						imgui.OpenPopup(u8'Создать новый ответ')
					end
					imgui.Separator()
					if #settingsList.buttons ~= 0 then
						for i=1, #settingsList.buttons do
							local sizeButton = imgui.ImVec2(240, 0)
							if imgui.Button(u8(settingsList.buttons[i].title), sizeButton) then
								imgui.StrCopy(sfist.title, u8(settingsList.buttons[i].title))
								sfist.stopRecon[0] = settingsList.buttons[i].stopRecon
								sfist.closePopup[0] = settingsList.buttons[i].closePopup
								sfist.startReconId[0] = settingsList.buttons[i].startReconId
								sfist.startReconAuthor[0] = settingsList.buttons[i].startReconAuthor
								local text = ''
								for n=1, #settingsList.buttons[i].command do
									if n == #settingsList.buttons[i].command then
										text = text..settingsList.buttons[i].command[n]
									else
										text = text..settingsList.buttons[i].command[n]..'\n'
									end
								end
								imgui.StrCopy(commandImgui, u8(text))
								selectedIntButton = i
								imgui.OpenPopup(u8'Редактировать ответ')
							end
							if i % 2 == 1 then imgui.SameLine() end
						end
					else
						if imgui.InvisibleButton('##new-answer',imgui.ImVec2(sizeX-165, sizeY-78)) then
							imgui.OpenPopup(u8'Создать новый ответ')
						end
						imgui.SetCursorPosY(sizeY/2-15)
						imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 0.1))
						imgui.CenterText(u8'Нажмите меня чтобы создать новый ответ')
						imgui.PopStyleColor(1)
					end
					if imgui.BeginPopupModal(u8'Создать новый ответ', false, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
						local pSize = imgui.ImVec2(500, 600)
						imgui.SetWindowSizeVec2(pSize)
						local sizeButton = imgui.ImVec2(pSize.x/2-7.6,0)
						if imgui.BeginChild('##begin-new-answer', imgui.ImVec2(pSize.x-10,pSize.y-63), true) then
							imgui.NewInputText('##title-button', sfist.title, pSize.x-20, u8'Название кнопки', 2)
							imgui.Separator()
							if imgui.Checkbox(u8'Закрыть маленькое окно', sfist.closePopup) then
								slist.closePopup = sfist.closePopup[0]
							end
							imgui.SameLine()
							imgui.SetCursorPosX(pSize.x-250)
							imgui.Text(u8'@aid - ID автор жалоб\n@anick - Nickname автор жалоб\n\n@rid - ID нарушитель жалоб\n@rnick - Nickname нарушитель жалоб\n\n@msg - Текст репорта')
							imgui.SetCursorPosY(68)
							if imgui.Checkbox(u8'Начать рекон ID автора', sfist.startReconAuthor) then
								sfist.startReconId[0] = false
								sfist.stopRecon[0] = false
								slist.startReconAuthor = sfist.startReconAuthor[0]
							end
							if imgui.Checkbox(u8'Начать рекон ID репорта', sfist.startReconId) then
								sfist.startReconAuthor[0] = false
								sfist.stopRecon[0] = false
								slist.startReconId = sfist.startReconId[0]
							end
							if imgui.Checkbox(u8'Выходить с рекона', sfist.stopRecon) then
								sfist.startReconId[0] = false
								sfist.startReconAuthor[0] = false
								slist.stopRecon = sfist.stopRecon[0]
							end
							imgui.Separator()
							local authorId = 123
							local authorNick = 'Author_Nick'
							local messageReport = u8'Сообщение'
							local reportId = 647
							local reportNick = 'Report_Nick'
							imgui.InputTextMultiline('##command-button',commandImgui, sizeof(commandImgui), imgui.ImVec2(pSize.x-20,pSize.y-600))
							local msg = (((((u8(u8:decode(str(commandImgui)))):gsub('@aid', authorId)):gsub('@anick', authorNick)):gsub('@msg', messageReport)):gsub('@rid', reportId)):gsub('@rnick', reportNick)
							imgui.Text(msg)
						imgui.EndChild()
						end
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
						if imgui.Button(u8'Сохранить', sizeButton) then
							if #u8:decode(str(commandImgui)) ~= 0 then
								if #u8:decode(str(sfist.title)) ~= 0 then
									lua_thread.create(function()
										local cof = {}
										local multi = u8:decode(str(commandImgui))..'\n'
										for msgmatch in multi:gmatch('.-\n') do
											local msgmatch = msgmatch:gsub('\n', '')
											if not msgmatch:find('^%s+$') and (#msgmatch ~= 0) then
												table.insert(cof, msgmatch)
											end
										end
										local list = {
											title = u8:decode(str(sfist.title)),
											command = cof,
											closePopup = sfist.closePopup[0],
											startReconAuthor = sfist.startReconAuthor[0],
											startReconId = sfist.startReconId[0],
											stopRecon = sfist.stopRecon[0]
										}
										table.insert(settingsList.buttons, list)
										alert('Кнопка "'..u8:decode(str(sfist.title))..'" создана')
										print('Кнопка "'..u8:decode(str(sfist.title))..'" создана')
										save()
										imgui.CloseCurrentPopup()
									end)
								else
									alert('Поле заголовка не указано!')
								end
							else
								alert('Поле команда не указано!')
							end
						end
						imgui.PopStyleColor(3)
						imgui.SameLine()
						if imgui.Button(u8'Закрыть', sizeButton) then
							imgui.CloseCurrentPopup()
						end

						if isKeyJustPressed(0x1B) then
							imgui.CloseCurrentPopup()
						end
					imgui.EndPopup()
					end
					if imgui.BeginPopupModal(u8'Редактировать ответ', false, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
						local pSize = imgui.ImVec2(500, 600)
						imgui.SetWindowSizeVec2(pSize)
						local sizeButton = imgui.ImVec2(pSize.x/3-6.65,0)
						if imgui.BeginChild('##begin-new-answer', imgui.ImVec2(pSize.x-10,pSize.y-63), true) then
							imgui.NewInputText('##title-button', sfist.title, pSize.x-20, u8'Название кнопки', 2)
							imgui.Separator()
							if imgui.Checkbox(u8'Закрыть маленькое окно', sfist.closePopup) then
								slist.closePopup = sfist.closePopup[0]
							end
							imgui.SameLine()
							imgui.SetCursorPosX(pSize.x-250)
							imgui.Text(u8'@aid - ID автор жалоб\n@anick - Nickname автор жалоб\n\n@rid - ID нарушитель жалоб\n@rnick - Nickname нарушитель жалоб\n\n@msg - Текст репорта')
							imgui.SetCursorPosY(68)
							if imgui.Checkbox(u8'Начать рекон ID автора', sfist.startReconAuthor) then
								sfist.startReconId[0] = false
								sfist.stopRecon[0] = false
								slist.startReconAuthor = sfist.startReconAuthor[0]
							end
							if imgui.Checkbox(u8'Начать рекон ID репорта', sfist.startReconId) then
								sfist.startReconAuthor[0] = false
								sfist.stopRecon[0] = false
								slist.startReconId = sfist.startReconId[0]
							end
							if imgui.Checkbox(u8'Выходить с рекона', sfist.stopRecon) then
								sfist.startReconId[0] = false
								sfist.startReconAuthor[0] = false
								slist.stopRecon = sfist.stopRecon[0]
							end
							imgui.Separator()
							local authorId = 123
							local authorNick = 'Author_Nick'
							local messageReport = u8'Сообщение'
							local reportId = 647
							local reportNick = 'Report_Nick'
							imgui.InputTextMultiline('##command-button',commandImgui, sizeof(commandImgui), imgui.ImVec2(pSize.x-20,pSize.y-600))
							local msg = (((((u8(u8:decode(str(commandImgui)))):gsub('@aid', authorId)):gsub('@anick', authorNick)):gsub('@msg', messageReport)):gsub('@rid', reportId)):gsub('@rnick', reportNick)
							imgui.Text(msg)
						imgui.EndChild()
						end
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.77, 0.33, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.77, 0.33, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.77, 0.33, 0.8))
						if imgui.Button(u8'Сохранить', sizeButton) then
							if #u8:decode(str(commandImgui)) ~= 0 then
								if #u8:decode(str(sfist.title)) ~= 0 then
									lua_thread.create(function()
										local cof = {}
										local multi = u8:decode(str(commandImgui))..'\n'
										for msgmatch in multi:gmatch('.-\n') do
											local msgmatch = msgmatch:gsub('\n', '')
											if not msgmatch:find('^%s+$') and (#msgmatch ~= 0) then
												table.insert(cof, msgmatch)
											end
										end

										settingsList.buttons[selectedIntButton].title = u8:decode(str(sfist.title))
										settingsList.buttons[selectedIntButton].command = cof
										settingsList.buttons[selectedIntButton].closePopup = sfist.closePopup[0]
										settingsList.buttons[selectedIntButton].startReconAuthor = sfist.startReconAuthor[0]
										settingsList.buttons[selectedIntButton].startReconId = sfist.startReconId[0]
										settingsList.buttons[selectedIntButton].stopRecon = sfist.stopRecon[0]

										alert('Кнопка "'..u8:decode(str(sfist.title))..'" отредактирована')
										print('Кнопка "'..u8:decode(str(sfist.title))..'" отредактирована')
										save()
										imgui.CloseCurrentPopup()
									end)
								else
									alert('Поле заголовка не указано!')
								end
							else
								alert('Поле команда не указано!')
							end
						end
						imgui.PopStyleColor(3)
						imgui.SameLine()
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.25, 0.25, 1.0))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.25, 0.25, 0.9))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.25, 0.25, 0.8))
						if imgui.Button(u8'Удалить', sizeButton) then
							table.remove(settingsList.buttons, selectedIntButton)
							save()
							imgui.CloseCurrentPopup()
						end
						imgui.PopStyleColor(3)
						imgui.SameLine()
						if imgui.Button(u8'Закрыть', sizeButton) then
							imgui.CloseCurrentPopup()
						end

						if isKeyJustPressed(0x1B) then
							imgui.CloseCurrentPopup()
						end
					imgui.EndPopup()
					end
				end
			imgui.EndChild()
			end
		imgui.End()
		end
	end
)

local reconFrame = imgui.OnFrame(
	function() return reconWindow[0] and not isGamePaused() end,
	function(self)

		if not reconCursor then
			reconCursor = true
			self.HideCursor = true
		end

		local resX, resY = getScreenResolution()
		local sizeX, sizeY = 500, 69
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY-40), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
		if imgui.Begin('##reconWindow', reconWindow, imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBackground) then
			local sizBut = imgui.ImVec2(77.5,0)
			local id = blockId
			imgui.Separator()
			if imgui.Button('GETSTATS', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/getstats '..blockId)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('OFFSTATS', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/getoffstats '..sampGetPlayerNickname(tonumber(blockId)))
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('SLAP', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/slap '..blockId)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('SPAWN', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/sp '..blockId)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('FREEZE', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/freeze '..id)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..id..' не в сети!')
				end
			end sl()

			if imgui.Button('UNFREEZE', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						sampSendChat('/unfreeze '..id)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end

			if imgui.Button('AZ', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							statusReconButton = true
							selectedAZ = id
							sampSendChat('/re off')
							wait(1000)
							sampSendChat('/tp')
							wait(3000)
							statusReconButton = false
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('GETHERE', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							statusReconButton = true
							sampSendChat('/re off')
							wait(1050)
							sampSendChat('/gethere '..id)
							statusReconButton = false
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('GOTO', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							statusReconButton = true
							sampSendChat('/re off')
							wait(1050)
							sampSendChat('/goto '..id)
							statusReconButton = false
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('GM', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							sampSendChat('/gm '..id)
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('IWEP', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							sampSendChat('/iwep '..id)
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end sl()

			if imgui.Button('VEH 462 6 6', sizBut) then
				if sampIsPlayerConnected(id) then
					if not statusReconButton then
						lua_thread.create(function()
							sampSendChat('/veh 462 6 6')
						end)
					else
						alert('Подождите ещё несколько секунды!')
					end
				else
					alert('Игрок с ID '..blockId..' не в сети!')
				end
			end
		imgui.End()
		end
	end
)

local keycapFrame = imgui.OnFrame(
    function() return target ~= -1 and not isGamePaused() end,
    function(self)

		if not keycapCursor and target ~= -1 then
			keycapCursor = true
			self.HideCursor = true
		else
			keycapCursor = false
		end

		imgui.SetNextWindowPos(imgui.ImVec2(sW / 2, sH - 116), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
		imgui.Begin("##KEYS", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoBackground)
			if doesCharExist(target) then
				imgui.CenterText(reconPlayerTip..'  >>  '..reconPlayerNick..'  >>  '..reconId)
				local plState = (isCharOnFoot(target) and "onfoot" or "vehicle")

				imgui.BeginGroup()
					imgui.SetCursorPosX(10 + 25 + 5)
					KeyCap("W", (keys[plState]["W"] ~= nil), imgui.ImVec2(30, 30))
					KeyCap("A", (keys[plState]["A"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
					KeyCap("S", (keys[plState]["S"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
					KeyCap("D", (keys[plState]["D"] ~= nil), imgui.ImVec2(30, 30))
				imgui.EndGroup()
				imgui.SameLine(nil, 20)

				if plState == "onfoot" then
					imgui.BeginGroup()
						KeyCap("Shift", (keys[plState]["Shift"] ~= nil), imgui.ImVec2(75, 30)); imgui.SameLine()
						KeyCap("Alt", (keys[plState]["Alt"] ~= nil), imgui.ImVec2(55, 30))
						KeyCap("Space", (keys[plState]["Space"] ~= nil), imgui.ImVec2(135, 30))
					imgui.EndGroup()
					imgui.SameLine()
					imgui.BeginGroup()
						KeyCap("C", (keys[plState]["C"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
						KeyCap("F", (keys[plState]["F"] ~= nil), imgui.ImVec2(30, 30))
						KeyCap("RM", (keys[plState]["RKM"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
						KeyCap("LM", (keys[plState]["LKM"] ~= nil), imgui.ImVec2(30, 30))		
					imgui.EndGroup()
				else
					imgui.BeginGroup()
						KeyCap("Ctrl", (keys[plState]["Ctrl"] ~= nil), imgui.ImVec2(65, 30)); imgui.SameLine()
						KeyCap("Alt", (keys[plState]["Alt"] ~= nil), imgui.ImVec2(65, 30))
						KeyCap("Space", (keys[plState]["Space"] ~= nil), imgui.ImVec2(135, 30))
					imgui.EndGroup()
					imgui.SameLine()
					imgui.BeginGroup()
						KeyCap("Up", (keys[plState]["Up"] ~= nil), imgui.ImVec2(40, 30))
						KeyCap("Down", (keys[plState]["Down"] ~= nil), imgui.ImVec2(40, 30))	
					imgui.EndGroup()
					imgui.SameLine()
					imgui.BeginGroup()
						KeyCap("H", (keys[plState]["H"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
						KeyCap("F", (keys[plState]["F"] ~= nil), imgui.ImVec2(30, 30))
						KeyCap("Q", (keys[plState]["Q"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
						KeyCap("E", (keys[plState]["E"] ~= nil), imgui.ImVec2(30, 30))
					imgui.EndGroup()
				end
			else
				target = -1
			end
		imgui.End()
    end
)

function main()
	while not isSampAvailable() do wait(0) end
	alert('Скрипт загружен | GitHub: kyrtion.me/herep | Menu: /shr | Version: '..thisScript().version)
	alert('Для появления курсора нажмите "левый Alt", открыть окно репорта "P"')
	-- memory.copy(0x4EB9A0, memory.strptr('\xC2\x04\x00'), 3, true)
	memory.write(sampGetBase() + 643864, 37008, 2, true)
	sampRegisterChatCommand('hr', function()
		mainWindow[0] = not mainWindow[0]
	end)

	sampRegisterChatCommand('shr', function()
		if not mainWindow[0] then
			menuWindow[0] = not menuWindow[0]
		else
			alert('Если Вы хотите настраивать, Вам необходимо скрыть окно для репорта')
			alert('Нажмите "P", чтобы скрыть окно репорта')
		end
	end)
	sampRegisterChatCommand('testhr', function()
		listReport = {}
		local list = {
			nick = 'Vika_Raskalova',
			id = 0,
			msg = '2 speedхак',
			status = false,
			timer = 0,
			recon = false,
			boolCount = false
		}
		table.insert(listReport, list)
	end)

	sampRegisterChatCommand('reportpos', function()
		if not menuWindow[0] then
			if not mainWindow[0] then mainWindow[0] = not mainWindow[0] end
			lua_thread.create(function ()
				checkCursor = true
				-- sampSetCursorMode(4)
				alert('Нажмите "SPACE" чтобы сохранить позицию')
				local lock = false
				while checkCursor do
					if not lock then sampSetCursorMode(3) lock = true end
					local cX, cY = getCursorPos()
					posX, posY = cX, cY
					if isKeyDown(32) then -- 32 = Space
						settingsList.settings2.positionX, settingsList.settings2.positionY = posX, posY
						checkCursor = false
						-- showCursor(false)
						sampSetCursorMode(0)
						save()
						alert('Сохранено')
					end
					wait(0)
				end
			end)
		else
			alert('Окно настройки должно быть скрыто, нажмите справо-вверху крестик')
		end
	end)

	sampRegisterChatCommand('hr_verify', function()
		if lockVerify then
			if mainWindow[0] or menuWindow[0] or sampIsDialogActive() then
				alert('Закройте диалог и снова вводите /hr_verify')
			else
				checkVerify = true
				alert('Обновляю '..oldVersion ..' -> '..newVersion..' ...')
				lockVerify = false
			end
		end
	end)

	-- Таймер, это мой альтернативный вариант
	lua_thread.create(function() while true do; wait(1000); if #listReport ~= 0 then; for i=1, #listReport do; listReport[i].timer = listReport[i].timer + 1; end; end; end; end)

	if boolEnableAutoUpdate then
		downloadUrlToFile(update_url, update_path, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				updateIni = inicfg.load(nil, update_path)
				if updateIni.info.version ~= nil or updateIni.info.version ~= '' then
					newVersion = tostring(updateIni.info.version):gsub('"', '')
					oldVersion = tostring(thisScript().version)
					-- alert('newVersion: '..newVersion..', oldVersion: '..oldVersion)
					if newVersion ~= oldVersion then
						alert('Есть обновление! Новая версия: '..newVersion..'. Для обновление введите /hr_verify')
						update_state = true
						lockVerify = true
					else
						alert('Проверил на обновление, всё в порядке. Версия актуальная')
					end
					os.remove(update_path)
				else
					alert('Невозможно проверить наличие обновление. Нажмите CTRL + R чтобы перезагрузить')
				end
			end
		end)
	end

	while true do
		wait(0)

		if isKeyJustPressed(0xA4) and (mainWindow[0] or reconWindow[0]) then
			if not cursorLock and sampGetCursorMode() ~= 3 then
    			sampSetCursorMode(3)
				cursorLock = true
			else
				sampSetCursorMode(0)
    			-- sampToggleCursor(false)
				cursorLock = false
			end
		end

		if blockId ~= -1 and sampIsPlayerConnected(blockId) and not reconWindow[0] then
			reconWindow[0] = true
		elseif reconWindow[0] and blockId == -1 then
			reconWindow[0] = false
		end

		if blockId ~= -1 then
			lua_thread.create(function()
				wait(100)
				targ(blockId)
			end)
		end

		if sampTextdrawIsExists(2143) then
			local textdraw_string = sampTextdrawGetString(2143)
			-- print(textdraw_string)
			-- helper-report-auto.lua: PC_PLAYER:~N~~Y~Maksim_Grimy (249)
			-- helper-report-auto.lua: ANDROID_PLAYER:~N~~Y~Nikita_Blond (35)
			if textdraw_string:find('^(.+)%_PLAYER%:%~N%~%~Y%~(.+) %((.+)%)$') then
				reconPlayerTip, reconPlayerNick, reconId = textdraw_string:match('^(.+)%_PLAYER%:%~N%~%~Y%~(.+) %((.+)%)$')
				if blockId ~= reconId then
					reconWindow[0] = true
					blockId = tonumber(reconId)
				end
			end
		end

		if boolEnableAutoUpdate and update_state and checkVerify then
			downloadUrlToFile(script_url, script_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					alert('Скрипт успешно обновлен! Сейчас будет перезагружен')
					lockFailed = true
					thisScript():reload()
				end
			end)
			break
		end
		if isKeyJustPressed(0x50) and not menuWindow[0] and not sampIsDialogActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
			mainWindow[0] = not mainWindow[0]
		end
		if #listReport ~= 0 and not listReport[1].status and not menuWindow[0] and settingsList.settings.showNewReport then
			if settingsList.settings.closeReport then statusSkip[0] = true end
			listReport[1].status = true
			selectPm[0] = true
			mainWindow[0] = true
		elseif mainWindow[0] and #listReport ~= 0 and not listReport[1].status then
			if settingsList.settings.closeReport then statusSkip[0] = true end
			listReport[1].status = true
			selectPm[0] = true
		end
		renderFontDrawText(font, 'Reports: '..#listReport, 10, resY-24, 0xFFFFFFFF)
		if #listReport ~= 0 and not mainWindow[0] then
			renderFontDrawText(font, 'Session: '..get_timer(listReport[1].timer), 105, resY-24, 0xFFFFFFFF)
		end
	end
end

function imgui.NewInputText(lable, val, width, hint, hintpos)
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val, sizeof(val))
    if #u8:decode(str(val)) == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function removeReport(array, bool)
	if #listReport ~= 0 then
		table.remove(listReport, array)
	end
	if bool then
		selectPm[0] = true
		statusSkip[0] = false
	end
end

function sampev.onPlayerQuit(playerId, reason)
	local playerId = tonumber(playerId)
	if #listReport ~= 0 then
		for i=1, #listReport do
			local idAuthor = tonumber(listReport[i].id)
			if playerId == idAuthor and not listReport[i].boolCount then
				if intCountReport > 0 then
					intCountReport = intCountReport - 1
				end
				listReport[i].boolCount = true
			end
		end
	end
	if closeIfLeaved then
		if #listReport >= 2 then
			for i=1, #listReport do
				local idAuthor = tonumber(listReport[i].id)
				if not listReport[i].status and playerId == idAuthor then
					table.remove(listReport, i)
				end
			end
		end
	end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function get_timer(time)
	-- return os.date('%H:%M:%S', 86400 - get_timezone() + time) -- 1.0
	return os.date('%H:%M:%S', 86400 - os.difftime(86400, os.time(os.date("!*t", 86400))) + time) -- 2.0
end

function sampGetListboxItemText(str, item)
	local num_ = 0
	for str in string.gmatch(str, "[^\r\n]+") do
		if item == num_ then return str end
		num_ = num_ + 1
	end
	return false
end

function sampGetListboxItemsCount(text)
	local i = 0
	for _ in text:gmatch(".-\n") do
		i = i + 1
	end
	return i
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if lockDefine and dialogId == 228 and style == 4 and title:find('%{FFC800%}Репорт') then
		lockDefine = false
		intCountReport = 0
		listReport = {}

		for i=0, sampGetListboxItemsCount(text)-1 do
			local mesa = sampGetListboxItemText(text, i)
			local f, DENick, DEId, DEMsg = (sampGetListboxItemText(text, i)):match('^%{33AA33%}(%d+)%. (.+)%[(%d+)%] | %{33CCFF%}Жалоба: (.+)$')
			local list = {
				nick = DENick,
				id = DEId,
				msg = DEMsg,
				status = false,
				timer = 0,
				recon = false,
				boolCount = false
			}
			table.insert(listReport, list)
		end
		intCountReport = #listReport
		return false
	elseif selectedAZ ~= -1 and dialogId == 9000 and style == 2 and title == '{179cf0}Куда Вы хотите телепортироваться?' then
		-- sampAddChatMessage('+', -1)
		lua_thread.create(function()
			sampSendDialogResponse(dialogId, 1, 0, '')
			wait(1000)
			sampSendChat('/gethere '..selectedAZ)
			selectedAZ = -1
		end)
		return false
	end
end

function sampev.onTogglePlayerSpectating(bool)
	statusRecon = bool
	if statusRecon and not lockRecon then
		lockRecon = true
	end
	-- reconWindow[0] = bool
	if not bool then
		target = -1
		blockId = -1
	end
end

function sampev.onSpectatePlayer(playerId, camType)
	playerIdRecon = playerId
end

function sampev.onShowMenu()
	if lockRecon and playerIdRecon ~= -1 then
		return false
	end
end

function sampev.onHideMenu()
	if lockRecon and playerIdRecon ~= -1 then
		return false
	end
end

function sampev.onSendSpawn()
	if not statusRecon and lockRecon then
		-- sampAddChatMessage('+', -1)
		-- nameTag(true)
		lockRecon = false
		-- nameTag(true)
		lua_thread.create(function()
			wait(200)
			freezeCharPosition(PLAYER_PED, true)
			freezeCharPosition(PLAYER_PED, false)
			setPlayerControl(PLAYER_HANDLE, true)
			restoreCameraJumpcut()
			clearCharTasksImmediately(PLAYER_PED)
		end)
	end
end

function targ(arg)
	arg = tonumber(arg)
	if arg ~= nil and sampIsPlayerConnected(tonumber(arg)) then
		local pedExist, ped = sampGetCharHandleBySampPlayerId(arg)
		if pedExist then
			target = ped
			return true
		end
		return
	end
end

function sampev.onPlayerSync(playerId, data)
	local result, id = sampGetPlayerIdByCharHandle(target)
	if result and id == playerId then
		keys["onfoot"] = {}

		keys["onfoot"]["W"] = (data.upDownKeys == 65408) or nil
		keys["onfoot"]["A"] = (data.leftRightKeys == 65408) or nil
		keys["onfoot"]["S"] = (data.upDownKeys == 00128) or nil
		keys["onfoot"]["D"] = (data.leftRightKeys == 00128) or nil

		keys["onfoot"]["Alt"] = (bit.band(data.keysData, 1024) == 1024) or nil
		keys["onfoot"]["Shift"] = (bit.band(data.keysData, 32) == 32) or nil
		keys["onfoot"]["Space"] = (bit.band(data.keysData, 8) == 8) or nil
		keys["onfoot"]["F"] = (bit.band(data.keysData, 16) == 16) or nil
		keys["onfoot"]["C"] = (bit.band(data.keysData, 2) == 2) or nil

		keys["onfoot"]["RKM"] = (bit.band(data.keysData, 4) == 4) or nil
		keys["onfoot"]["LKM"] = (bit.band(data.keysData, 128) == 128) or nil
	end
end

function sampev.onVehicleSync(playerId, vehicleId, data)
	local result, id = sampGetPlayerIdByCharHandle(target)
	if result and id == playerId then
		keys["vehicle"] = {}

		keys["vehicle"]["W"] = (bit.band(data.keysData, 8) == 8) or nil
		keys["vehicle"]["A"] = (data.leftRightKeys == 65408) or nil
		keys["vehicle"]["S"] = (bit.band(data.keysData, 32) == 32) or nil
		keys["vehicle"]["D"] = (data.leftRightKeys == 00128) or nil

		keys["vehicle"]["H"] = (bit.band(data.keysData, 2) == 2) or nil
		keys["vehicle"]["Space"] = (bit.band(data.keysData, 128) == 128) or nil
		keys["vehicle"]["Ctrl"] = (bit.band(data.keysData, 1) == 1) or nil
		keys["vehicle"]["Alt"] = (bit.band(data.keysData, 4) == 4) or nil
		keys["vehicle"]["Q"] = (bit.band(data.keysData, 256) == 256) or nil
		keys["vehicle"]["E"] = (bit.band(data.keysData, 64) == 64) or nil
		keys["vehicle"]["F"] = (bit.band(data.keysData, 16) == 16) or nil

		keys["vehicle"]["Up"] = (data.upDownKeys == 65408) or nil
		keys["vehicle"]["Down"] = (data.upDownKeys == 00128) or nil
	end
end

function sampev.onServerMessage(color, text)
	-- print(text)
	if settingsList.settings.hideAd then
		if text == ('' or '%s+' or '%s') then return false
		elseif color == -520093782 and (
			text == '<< Vladimir_Putin: {F04245}АКЦИЯ! {F04245}АКЦИЯ! {F04245}АКЦИЯ! {E0FFFF}>>' or
			text == '<< Vladimir_Putin: {E0FFFF}Низкие цены на привилегии только сегодня! (/donaterub) >>' or
			text == '<< Vladimir_Putin: {E0FFFF}Cтань ВЛАДЕЛЬЦЕМ сервера (Полный доступ) {F04245}всего за 2990 рублей! {E0FFFF}>>' or
			text == '<< Vladimir_Putin: {E0FFFF}Для покупки используйте команду — /buyowner >>' or
			text == '<< Vladimir_Putin: {E0FFFF}Не упустите такую возможность! >>'
		) then return false
		elseif color == -1191240961 and (
			text == '[A] Сегодня низкие цены в админ-магазине (/adonate)' or
			text == '[A] Чтобы пополнить игровой счёт, перейдите на наш сайт (russia-samp.ru)'
		) then return false
		elseif color == 13304063 and (text:find('russia%-samp%.ru') or text:find('АКЦИЯ') or text:find('НИЗКИЕ ЦЕНЫ') or text:find('чтобы онлайн побыстрее набрался')) then return false
		elseif color == -1199174657 and (
			text == '[UPDATE]: Для повышения своего уровня админ-прав, используйте: /adonate' or
			text == '[UPDATE]: Также, в магазине для администрации скидки, подробнее: /adonate'
		) then return false
		elseif color == -1347440726 and text == "Для того, чтобы закончить слежку за игроком, введите: '/re off'" then
			return false
		end
	end

	if color == -1191240961 then
		print(color, text)
		new_text = text
		if settingsList.settings.hideFloodInAdminChat then
			if new_text == old_text then
				return false
			else
				old_text = text
			end
		end
	end

	if color == -578720769 and text:find('^Репорт от (.+)%[(%d+)%]%: (.+)$') then
		intCountReport = intCountReport + 1
		local RTNick, RTId, RTMsg = text:match('^Репорт от (.+)%[(%d+)%]%: (.+)$')
		local RTMsg = RTMsg:gsub('^%{FFFFFF%}', '')
		local list = {
			nick = RTNick,
			id = RTId,
			msg = RTMsg,
			status = false,
			timer = 0,
			recon = false,
			boolCount = false
		}
		table.insert(listReport, list)
		print('{FF0000}Added[t'..(#listReport)..']: '..RTNick..' '..RTId..' '..RTMsg)
	elseif color == -270686209 and text:find('^%[A%] (.+)%[(%d+)%] ответил игроку (.+)%[(%d+)%]%: %{FFFFFF%}(.+)$') then
		local PMAdminNick, PMAdminId, PMNick, PMId, PMMsg = text:match('^%[A%] (.+)%[(%d+)%] ответил игроку (.+)%[(%d+)%]%: %{FFFFFF%}(.+)$')
		print('{FF00FF}PM: '..PMAdminNick..'['..PMAdminId..'] -> '..PMNick..'['..PMId..']: '..PMMsg)
		for i=1, #listReport do
			if listReport[i].nick == PMNick and listReport[i].id == PMId and not listReport[i].boolCount then
				intCountReport = intCountReport - 1
				listReport[i].boolCount = true
			end
			if not listReport[i].status and listReport[i].nick == PMNick then
				print('{FFFF00}Removed[t'..(#listReport - 1)..']: '..PMAdminNick..'['..PMAdminId..'] -> '..PMNick..'['..PMId..']: '..PMMsg)
				removeReport(i, false)
				break
			end
		end
		if settingsList.settings.otherPm and PMAdminNick ~= sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
			print('('..color..') | '..text)
			return false
		end
	elseif lockDefine and color == -1439485014 and text == 'Список жалоб пуст' then
		lockDefine = false
		intCountReport = 0
	end

	-- (-270686209) || [A] Snegovik_Ya[1] ответил игроку Vadim_Rampage[7]: {FFFFFF}test
	if settingsList.settings2.boolPMNick and color == -270686209 and text:find('^%[A%] (.+)%[(%d+)%] ответил игроку (.+)%[(%d+)%]%:(.+)$') then
		local admin, aid, nick, nid, msg = text:match('^%[A%] (.+)%[(%d+)%] ответил игроку (.+)%[(%d+)%]%:(.+)$')
		local msg = msg:gsub('^ %{FFFFFF%}', ''):gsub('^%{FFFFFF%}', '')
		local msg = (settingsList.settings2.boolPMText and intToHex(join_argb(settingsList.settings2.colorPMText.a, settingsList.settings2.colorPMText.r, settingsList.settings2.colorPMText.g, settingsList.settings2.colorPMText.b)) or '')..msg:gsub('%{FFFFFF%}', '')
		local ftext = '[PM] '..admin..'['..aid..'] > '..nick..'['..nid..']: '..msg
		sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPMNick.a, settingsList.settings2.colorPMNick.r, settingsList.settings2.colorPMNick.g, settingsList.settings2.colorPMNick.b))
		return false
	end
	-- (-578720769) || Репорт от Snegovik_Ya[1]: {FFFFFF}asd
	if settingsList.settings2.boolReportNick and color == -578720769 and text:find('^Репорт от (.+)%[(%d+)%]%: (.+)$') then
		local nick, id, msg = text:match('^Репорт от (.+)%[(%d+)%]%: (.+)$')
		local msg = (settingsList.settings2.boolReportText and intToHex(join_argb(settingsList.settings2.colorReportText.a, settingsList.settings2.colorReportText.r, settingsList.settings2.colorReportText.g, settingsList.settings2.colorReportText.b)) or '')..msg:gsub('^%{FFFFFF%}', '')
		-- local ftext = '[Репорт] '..nick..'['..id..']: {FA7D4B}'..msg..(boolCountReport and '. Уже '..intCountReport..' репортов!')
		
		local ftext = 'Репорт от '..nick..'['..id..']: '..msg..'. Уже '..intCountReport..' репортов!'
		sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorReportNick.a, settingsList.settings2.colorReportNick.r, settingsList.settings2.colorReportNick.g, settingsList.settings2.colorReportNick.b))
		return false
	end

	if settingsList.settings2.boolPunishment then
		if color == -10270806 then -- red 
			-- (-10270806) || Администратор Snegovik_Ya заблокировал чат игроку Father_Rimskiy на 10 минут. Причина: /vad
			if text:find('^Администратор (.+) заблокировал чат игроку (.+) на (.+) минут%. Причина%:(.+)$') then
				local admin, nick, min, reason = text:match('^Администратор (.+) заблокировал чат игроку (.+) на (.+) минут%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' заблокировал чат игроку '..nick..' на '..min..' минут. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) заблокировал чат игроку (.+)%. Причина%:(.+)$') then
				local admin, nick, reason = text:match('^Администратор (.+) заблокировал чат игроку (.+)%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' заблокировал чат игроку '..nick..'. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) заблокировал доступ к репорту игроку (.+) на (.+) минут%. Причина%:(.+)$') then
				local admin, nick, min, reason = text:match('^Администратор (.+) заблокировал доступ к репорту игроку (.+) на (.+) минут%. Причина:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' заблокировал репорт игроку '..nick..' на '..min..' минут. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) снял блокировку репорта у (.+)$') then
				local admin, nick = text:match('^Администратор (.+) снял блокировку репорта у (.+)$')
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' снял блокировку репорта у '..nick
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) снял блокировку чата у (.+)$') then
				local admin, nick = text:match('^Администратор (.+) снял блокировку чата у (.+)$')
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' снял блокировку чата у '..nick
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) кикнул с пейнтбола игрока (.+)%. Причина%:(.+)$') then
				local admin, nick, reason = text:match('^Администратор (.+) кикнул с пейнтбола игрока (.+)%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' кикнул с пейнтбола игрока '..nick..'. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			-- elseif text:find('^Администратор (.+) заблокировал IP адрес%: (.+) на (.+) дней%. Причина%:(.+)$') then
			elseif text:find('^Администратор (.+) заблокировал IP адрес%: (.*) на (%d+) дней%. Причина%:(.+)$') then
				-- (-10270806) || Администратор Jim_Reed заблокировал IP адрес: 4.3.2.1 на 7 дней. Причина: IZP
				local admin, ip, days, reason = text:match('^Администратор (.+) заблокировал IP адрес%: (.*) на (%d+) дней%. Причина%:(.+)$')
				print('>'..admin..'<|>'..ip..'<|>'..days..'<|>'..reason..'<')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local ftext = 'Администратор '..admin..' заблокировал IP-адрес '..ip..' на '..days..' дней. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) заблокировал игрока%: (.+) на (%d+) дней%. Причина%:(.*)$') then
				local admin, nick, days, reason = text:match('^Администратор (.+) заблокировал игрока%: (.+) на (%d+) дней%. Причина%:(.*)$')
				print(admin, nick, days, reason)
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local ftext = 'Администратор '..admin..' в оффлайне заблокировал '..nick..' на '..days..' дней. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) заблокировал бессрочно (.+)%. Причина%:(.+)$') then
				local admin, nick, reason = text:match('^Администратор (.+) заблокировал бессрочно (.+)%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' заблокировал бессрочно '..nick..'. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^%[SBAN%] Администратор (.+) забанил (.+) на (.+) дней%. %[Причина%:(.+)%]') then
				local admin, nick, days, reason = text:match('^%[SBAN%] Администратор (.+) забанил (.+) на (.+) дней%. %[Причина%:(.+)%] %[(.+) (.+)%]')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' тихо заблокировал игрока '..nick..' на '..days..' дней. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^Администратор (.+) заблокировал (.+) на (.+) дней%. Причина%:(.+)$') then
				local admin, nick, days, reason = text:match('^Администратор (.+) заблокировал (.+) на (.+) дней%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local ftext = 'Администратор '..admin..' заблокировал '..nick..' на '..days..' дней. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
				-- end
			elseif text:find('^Администратор (.+) кикнул (.+)%. Причина%:(.+)$') then
				local admin, nick, reason = text:find('^Администратор (.+) кикнул (.+)%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				-- local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' кикнул '..nick..'. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			end
		elseif color == -1347440726 then -- grey
			-- (-1347440726) || [A] Snegovik_Ya посадил игрока Snegovik_Ya в деморган на 1 минут. Причина: test
			if text:find('^%[A%] (.+) посадил игрока (.+) в деморган на (.+) минут%. Причина%:(.+)$')  then
				local admin, nick, min, reason = text:match('^%[A%] (.+) посадил игрока (.+) в деморган на (.+) минут%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' посадил игрока '..nick..' в деморган на '..min..' минут. Причина:'..reason
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^%[A%] (.+) освободил игрока (.+) из деморгана$')  then
				local admin, nick = text:match('^%[A%] (.+) освободил игрока (.+) из деморгана$')
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				local nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
				local ftext = 'Администратор '..admin..' выпустил '..nick..' из деморгана'
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
				return false
			elseif text:find('^%[A%] (.+) тихо кикнул (.+)%. Причина%:(.+)$') then
				local admin, nick, reason = text:match('^%[A%] (.+) тихо кикнул (.+)%. Причина%:(.+)$')
				local reason = reason or '*не указана*'
				local admin = admin..'['..sampGetPlayerIdByNickname(admin)..']'
				if sampIsPlayerConnected(sampGetPlayerIdByNickname(nick)) then
					nick = nick..'['..sampGetPlayerIdByNickname(nick)..']'
					local ftext = 'Администратор '..admin..' тихо кикнул '..nick..'. Причина:'..reason
					sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
					return false
				else
					local ftext = 'Администратор '..admin..' тихо кикнул '..nick..'. Причина:'..reason
					sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorPunishment.a, settingsList.settings2.colorPunishment.r, settingsList.settings2.colorPunishment.g, settingsList.settings2.colorPunishment.b))
					return false
				end
			end
		end
		if (color == -10270806 and text:find('Ник%: %[(.+)%]')) or text:find('^%{FFFFFF%}Ник%: %{FF0000%}%[(.+)%]$') then return false end
	end

	if settingsList.settings2.boolAdminChatNick then
		-- (-1191240961) || [A-11] Snegovik_Ya[13]: asd
		if color == -1191240961 and text:find('^%[(.+)%] (.+)%[(%d+)%]%:(.*)') then
			if settingsList.settings2.boolFormatAdminChat then
				local prefix, nick, id, msg = text:match('^%[(.+)%] (.+)%[(%d+)%]%:(.*)')
				local msg = msg:gsub('^ ', '') or '*не указана*'
				local msg = (settingsList.settings2.boolAdminChatText and intToHex(join_argb(settingsList.settings2.colorAdminChatText.a, settingsList.settings2.colorAdminChatText.r, settingsList.settings2.colorAdminChatText.g, settingsList.settings2.colorAdminChatText.b)))..msg
				-- local prefix = prefix:gsub('A%-', '')
				local ftext = (settingsList.settings2.textFormatAdminChat):gsub('@prefix', prefix):gsub('@nick', nick):gsub('@id', id):gsub('@msg', msg)
				sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorAdminChatNick.a, settingsList.settings2.colorAdminChatNick.r, settingsList.settings2.colorAdminChatNick.g, settingsList.settings2.colorAdminChatNick.b))
				return false
			else
				sampAddChatMessage(text:gsub('%{......%}', ''), join_argb(settingsList.settings2.colorAdminChatNick.a, settingsList.settings2.colorAdminChatNick.r, settingsList.settings2.colorAdminChatNick.g, settingsList.settings2.colorAdminChatNick.b))
				return false
			end
		-- (-86) || {B8FF1A}[A] Salvadore_Harley отключился (13 уровень) | Отыграл:  2:06
		elseif color == -86 and text:find('^%{......}%[A%] (.+) отключился %((%d+) уровень%) | Отыграл%:  (%d+)%:(%d+)$') then
			local ftext = text:gsub('%{......%}', ''):gsub('%[A%]', '[ALogin]')
			sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorAdminChatNick.a, settingsList.settings2.colorAdminChatNick.r, settingsList.settings2.colorAdminChatNick.g, settingsList.settings2.colorAdminChatNick.b))
			return false
		-- (-855703297) || {B8FF1A}[ALogin] Kevin_McKevi[9] авторизовался как администратор 3 уровня [Israel / Unknown]
		elseif color == -855703297 and text:find('%[ALogin%] (.+)%[(%d+)%] авторизовался как администратор (%d+) уровня') then
			local ftext = text:gsub('%{......%}', '')
			sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorAdminChatNick.a, settingsList.settings2.colorAdminChatNick.r, settingsList.settings2.colorAdminChatNick.g, settingsList.settings2.colorAdminChatNick.b))
			return false
		end
	end

	if settingsList.settings2.boolAntiCheat then
		-- (-1347440726) || RussiaGuard | [Подозрение] Yamaha_Moon[6]: SpeedHack (в машине) [код: #010]
		-- (-1347440726) || RussiaGuard | Kevin_McKevi[3] был кикнут за использование читов [код #000 | ping 119 | packetloss 0.29]
		if color == -1347440726 and text:find('^RussiaGuard | %[Подозрение%] (.+)%[(%d+)%]') or text:find('^RussiaGuard | (.+)%[(%d+)%] был кикнут за использование читов') then
			-- local ftext = text:gsub('RussiaGuard |', '[Античит]')
			sampAddChatMessage(text, join_argb(settingsList.settings2.colorAntiCheat.a, settingsList.settings2.colorAntiCheat.r, settingsList.settings2.colorAntiCheat.g, settingsList.settings2.colorAntiCheat.b))
			return false
		end
	end

	if settingsList.settings2.boolOtherPrefixA then
		-- (-1347440726) || [A] Theodore_Montana[6] подключился к серверу
		if color == -1347440726 then
			local ftext = text
			sampAddChatMessage(ftext, join_argb(settingsList.settings2.colorOtherPrefixA.a, settingsList.settings2.colorOtherPrefixA.r, settingsList.settings2.colorOtherPrefixA.g, settingsList.settings2.colorOtherPrefixA.b))
			return false
		end
	end
end

function showCursor(toggle)
	if toggle then
		sampSetCursorMode(CMODE_LOCKCAM)
	else
		sampToggleCursor(false)
	end
end

function sampGetPlayerIdByNickname(arg1)
	arg1 = tostring(arg1)
	local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if arg1 == sampGetPlayerNickname(myid) then 
		return myid
	end
	-- if not sampIsPlayerConnected(arg1) then return -1 end
	for i = 0, 1003 do
		if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == arg1 then
			return i
		end
	end
end

function imgui.CenterText(text)
	imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
	imgui.Text(text)
end

function imgui.TextS(text, clr)
	if clr then imgui.PushStyleColor(ffi.C.ImGuiCol_Text, clr) end

	text = ffi.new('char[?]', #text + 1, text)
	local text_end = text + ffi.sizeof(text) - 1
	local pFont = imgui.GetFont()

	local scale = 1.0
	local endPrevLine = pFont:CalcWordWrapPositionA(scale, text, text_end, imgui.GetContentRegionAvail().x)
	imgui.TextUnformatted(text, endPrevLine)

	while endPrevLine < text_end do
		text = endPrevLine
		if text[0] == 32 then text = text + 1 end
		endPrevLine = pFont:CalcWordWrapPositionA(scale, text, text_end, imgui.GetContentRegionAvail().x)
		if text == endPrevLine then
			endPrevLine = endPrevLine + 1
		end
		imgui.TextUnformatted(text, endPrevLine)
	end

	if clr then imgui.PopStyleColor() end
end

function imgui.DarkTheme()
	imgui.SwitchContext()
	--==[ STYLE ]==--
	imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
	imgui.GetStyle().IndentSpacing = 0
	imgui.GetStyle().ScrollbarSize = 10
	imgui.GetStyle().GrabMinSize = 10

	--==[ BORDER ]==--
	imgui.GetStyle().WindowBorderSize = 1
	imgui.GetStyle().ChildBorderSize = 1
	imgui.GetStyle().PopupBorderSize = 1
	imgui.GetStyle().FrameBorderSize = 0
	imgui.GetStyle().TabBorderSize = 0

	--==[ ROUNDING ]==--
	imgui.GetStyle().WindowRounding = 6
	imgui.GetStyle().ChildRounding = 5
	imgui.GetStyle().FrameRounding = 3
	imgui.GetStyle().PopupRounding = 5
	imgui.GetStyle().ScrollbarRounding = 5
	imgui.GetStyle().GrabRounding = 5
	imgui.GetStyle().TabRounding = 5

	--==[ ALIGN ]==--
	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
	
	--==[ COLORS ]==--
	imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(1.00, 1.00, 1.00, 0.30)
	imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
	imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
	imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
	imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
	imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
	imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
	imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function KeyCap(keyName, isPressed, size)
	local DL = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	local colors = {
		
		[false] = imgui.ImVec4(0.12, 0.12, 0.12, 0.8),
		-- [false] = imgui.ImVec4(0.60, 0.60, 1.00, 0.03),
		-- [true] = imgui.ImVec4(0.404,0.169,1.0, 1.00) -- blue
		[true] = imgui.ImVec4(0.60, 0.60, 1.00, 0.90) -- vanilla
	}

	if KEYCAP == nil then KEYCAP = {} end
	if KEYCAP[keyName] == nil then
		KEYCAP[keyName] = {
			status = isPressed,
			color = colors[isPressed],
			timer = nil
		}
	end

	local K = KEYCAP[keyName]
	if isPressed ~= K.status then
		K.status = isPressed
		K.timer = os.clock()
	end

	local rounding = 3.0
	local A = imgui.ImVec2(p.x, p.y)
	local B = imgui.ImVec2(p.x + size.x, p.y + size.y)
	if K.timer ~= nil then
		K.color = bringVec4To(colors[not isPressed], colors[isPressed], K.timer, 0.001)
	end
	local ts = imgui.CalcTextSize(keyName)
	local text_pos = imgui.ImVec2(p.x + (size.x / 2) - (ts.x / 2), p.y + (size.y / 2) - (ts.y / 2))

	imgui.Dummy(size)
	DL:AddRectFilled(A, B, u32(K.color), rounding)
	-- DL:AddRect(A, B, u32(colors[false]), rounding, _, 1)
	DL:AddText(text_pos, 0xFFFFFFFF, keyName)
end

function bringVec4To(from, dest, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return imgui.ImVec4(
            from.x + (count * (dest.x - from.x) / 100),
            from.y + (count * (dest.y - from.y) / 100),
            from.z + (count * (dest.z - from.z) / 100),
            from.w + (count * (dest.w - from.w) / 100)
        ), true
    end
    return (timer > duration) and dest or from, false
end

function onScriptTerminate(s, q)
	if s == thisScript() then
		if not lockFailed then
			alert('Скрипт перестал работать. Нажмите "CTRL + R" чтобы перезагрузить.')
		end
		sampSetCursorMode(0)
	end
end
