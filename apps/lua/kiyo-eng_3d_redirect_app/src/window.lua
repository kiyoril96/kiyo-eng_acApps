function layer3DController()
    
        ui.columns(5)
        ui.dwriteText('Layer')
        ui.offsetCursorY(10)
        --ui.setColumnWidth(0, 50)
        ui.nextColumn()
        ui.dwriteText('Position')
        --ui.setColumnWidth(1, 200)
        ui.nextColumn()
        ui.dwriteText('Rotation')
        --ui.setColumnWidth(2, 200)
        ui.nextColumn()
        ui.dwriteText('Visiblity')
        --ui.setColumnWidth(3, 200)
        ui.nextColumn()
        ui.dwriteText('Misc')
        --ui.setColumnWidth(4, 50)
        ui.nextColumn()

    if contorollerInit == false then 
        ui.setColumnWidth(0, 50)
        ui.setColumnWidth(1, 150)
        ui.setColumnWidth(2, 150)
        ui.setColumnWidth(3, 150)
        ui.setColumnWidth(4, 150)
        contorollerInit = true
    end

    for i=1,#layerList do
        if layerList[i] ~= nil and #layerList[i].apps ~= 0 then 
            -- layer num
            ui.dwriteText(i)
            ui.nextColumn()
            -- position
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsetx'..i, layerList[i].uioffsetx, -1, 1, 'OFFSETX: %.04f')
            if changed then layerList[i].uioffsetx = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsety'..i, layerList[i].uioffsety, -1, 1, 'OFFSETY: %.04f')
            if changed then layerList[i].uioffsety = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsetz'..i, layerList[i].uioffsetz, -1, 1, 'OFFSETZ: %.04f')
            if changed then layerList[i].uioffsetz = value end
            ui.offsetCursorY(10)
            ui.nextColumn()
            -- rotation
            ui.setNextItemWidth(-20)
            local value,changed = ui.slider('##rotationx'..i, layerList[i].rotationx, -90, 90, 'ROTATIONX: %.02f')
            if changed then layerList[i].rotationx = value end
            ui.sameLine()
            if ui.button('R ##resetx'..i) then layerList[i].rotationx = 0 end

            ui.setNextItemWidth(-20)
            local value,changed = ui.slider('##rotationy'..i, layerList[i].rotationy, -90, 90, 'ROTATIONY: %.02f')
            if changed then layerList[i].rotationy = value end
            ui.sameLine()
            if ui.button('R ##resety'..i) then layerList[i].rotationy = 0 end

            ui.setNextItemWidth(-20)
            local value,changed = ui.slider('##rotationz'..i, layerList[i].rotationz, -90, 90, 'ROTATIONZ: %.02f')
            if changed then layerList[i].rotationz = value end
            ui.sameLine()
            if ui.button('R ##resetz'..i) then layerList[i].rotationz = 0 end
            ui.nextColumn()
            -- size
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uisize'..i, layerList[i].uisize, 0, 1, 'SIZE: %.02f')
            if changed then layerList[i].uisize = value end
            -- brightness
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##brightness'..i, layerList[i].brightness, 0, 50, 'BRIGHTNESS: %.0f')
            if changed then layerList[i].brightness = value end
            -- opacity
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##OPACITY'..i, layerList[i].opacity, 0, 3, 'OPACITY: %.02f')
            if changed then layerList[i].opacity = value end
            ui.nextColumn()
            ---- obs
            --if ui.checkbox('##OBS'..i, layerList[i].visible) then
            --    layerList[i].visible = not  layerList[i].visible
            --end
            --ui.sameLine()
            --ui.dwriteText('OBS')
            ---- debug
            if ui.checkbox('##DEBUGPOINT'..i, layerList[i].visible) then
                layerList[i].visible = not  layerList[i].visible
            end
            ui.sameLine()
            ui.dwriteText('Debug Point')
            ui.nextColumn()
        end
    end
end

function genlabel(num)
    local ret
    if num == 0 then ret = 'OFF' else ret = num end
    return ret
end

function nonblank(name1 ,name2) 
    if name1 == "" then return name2 else return name1 end
end


local showAll = false
-- 3d表示、複製を制御するUI
function redirectSelecter()
    windowlist = ac.getAppWindows()
    ui.columns(3)
    ui.dwriteText('App Name')
    ui.offsetCursorY(10)
    ui.nextColumn()
    ui.dwriteText('Redirect Layer')
    ui.nextColumn()
    ui.dwriteText('Duplicate')
    ui.nextColumn()

    if contorollerInit == false then 
        ui.setColumnWidth(0, 200)
        ui.setColumnWidth(1, 200)
        ui.setColumnWidth(2, 100)
        ui.setColumnWidth(3, 100)
        contorollerInit = true
    end
    -- For 入れ子はちょっとパフォーマンスに問題ありか…？
    -- ↑ まあ表示してる間だけの処理だし...
    for i = 1 ,#windowlist do
        -- 表示されていないアプリと自分自身を除く
        if (windowlist[i].visible or showAll) 
            and windowlist[i].name ~= 'IMGUI_LUA_kiyo-eng_3d_redirect_app_main' 
            and windowlist[i].name ~= nil then 
            ui.offsetCursorX(5)
            local color = rgbm.colors.white
            if windowlist[i].visible == false then color = rgbm.colors.gray end
            ui.dwriteText( nonblank( windowlist[i].title, windowlist[i].name ),nil ,color) 
            ui.offsetCursorY(5)
            ui.nextColumn()
            ui.setNextItemWidth(-0.1)
            ui.combo('##layerSelecter'..i,genlabel(windowlist[i].layer),function() 
                -- 選択した数値のレイヤーへ転送する
                for y=0 , #layerList + 1  do 
                    if ui.selectable(genlabel(y)) then
                        -- 現在リダイレクトされているレイヤーを取得（管理用テーブル操作のため）
                        local curlayer = ac.accessAppWindow(windowlist[i].name):redirectLayer(refbool(false))
                        if layerList[curlayer] ~= nil and layerList[curlayer].apps ~= nil then
                            table.removeItem( layerList[curlayer].apps, windowlist[i].name )
                        end
                        local layer_in = layerList[y] or {
                            layer = y , pos = windowSize ,size = vec2(0,0),obs = false 
                            ,layerSize = vec2(0,0)
                            ,uioffsetx = 0 ,uioffsety = 0 ,uioffsetz = 0
                            ,rotationx = 0 ,rotationy = 0 ,rotationz = 0
                            ,uisize = 0.1
                            ,visible = false
                            ,brightness = 10
                            ,opacity = 1
                            ,apps={} }
                        table.insert(layer_in.apps, windowlist[i].name)
                        -- ここでリダイレクトの処理
                        local accesser = ac.accessAppWindow(windowlist[i].name)
                        accesser:setRedirectLayer(y,windowlist[i].layerDuplicate)
                        --layer_in.pos = accesser:position():min(layer_in.pos)
                        --layer_in.size = (accesser:position()+accesser:size()):max(layer_in.pos)
                        layerList[y] = layer_in
                    end 
                end
            end )
            ui.nextColumn()
            local dupStore = nil
            if ui.checkbox('##layerDuplicateSwitcher'..i,windowlist[i].layerDuplicate) and not dupStore then
                -- チェック入れたらDuplicate
                ac.accessAppWindow(windowlist[i].name):setRedirectLayer(windowlist[i].layer,not windowlist[i].layerDuplicate)
                dupStore = windowlist[i].layerDuplicate
            end
            ui.nextColumn() 
        end
    end
end 

local settingName = nil
local selectedSetting = configNames:get('CONFIGS','config_'..configNames:get('SELECTED','select',0),"default")
local settingOnStart = configNames:get('CONFIGS','config_'..configNames:get('STARTUP','select',0),"default")
--ac.debug('confignames',configNames:get('CONFIGS','config_'..configNames:get('SELECTED','select',0),"name"))
function windowMain()
    ui.tabBar('##3duiconfig',ui.TabBarFlags.None,function() 

        ui.tabItem('App Redirect',function()
            ui.childWindow('redirectSelecter',(ui.availableSpace()+vec2(0,-30)),redirectSelecter)
            ui.offsetCursorX(ui.availableSpaceX()-250)
            if ui.button('try Reflesh',vec2(90,25)) then
                windowListReflesh()
            end
            ui.sameLine()
            if ui.checkbox('##SHOWALL', showAll) then
                showAll = not  showAll
            end
            ui.sameLine()
            ui.dwriteText('Show All Apps')
        end)

        ui.tabItem('Contoroller',function()
            ui.childWindow('3DController',ui.availableSpace(),layer3DController)
        end )

        ui.tabItem('Save and Load',function()
            ui.childWindow('saveAndLoad',ui.availableSpace(),function()
                ui.dwriteText('Save Settings',20)
                ui.dwriteText('Settings Name : ')
                ui.sameLine()
                ui.setNextItemWidth(-100)
                settingName = ui.inputText('SettingsName',settingName,ui.InputTextFlags.Placeholder,vec2(0,40))
                ui.sameLine()
                if ui.button('SAVE',vec2(50,40)) then
                    saveSettings(settingName)
                end
                ui.offsetCursorY(30)
                ui.dwriteText('Load Settings',20)
                ui.dwriteText('Select Settings : ')
                ui.sameLine()
                ui.setNextItemWidth(-100)
                ui.combo('##settingsSelecter',selectedSetting,function() 
                    for index,key in configNames:iterateValues('CONFIGS','config',true) do
                        if ui.selectable(configNames:get('CONFIGS',key,"name")) then
                            selectedSetting = configNames:get('CONFIGS',key,"name")
                            configNames:set('SELECTED','select',index-1)
                        end
                    end
                end ) 
                ui.sameLine()
                if ui.button('LOAD ##load',vec2(50,40),ui.ButtonFlags.None) then
                    loadSettings(selectedSetting)
                end
                ui.offsetCursorY(30)
                ui.dwriteText('Load Settings on Starup',20)
                ui.dwriteText('Select Settings : ')
                ui.sameLine()
                ui.setNextItemWidth(-100)
                ui.combo('##onStartup',settingOnStart,function() 
                    for index,key in configNames:iterateValues('CONFIGS','config',true) do
                        if ui.selectable(configNames:get('CONFIGS',key,"name")) then
                            settingOnStart = configNames:get('CONFIGS',key,"name")
                            configNames:set('STARTUP','select',index-1)
                            configNames:save()
                        end
                    end
                end )
                
            end)
        end)
    end)
end

function getSettingsList()
    
end

function windowListReflesh()
    for i=1 ,#windowlist do
        if windowlist[i].layer >= 1 then
            local accesser = ac.accessAppWindow(windowlist[i].name)
            accesser:setRedirectLayer(0)
        end
    end 
    layerList = {}
end

function saveSettings(name)

    for i=1 ,#windowlist do
        if windowlist[i].layer >= 1 then
            local duplicate = nil
            if windowlist[i].layerDuplicate then duplicate = 1 else duplicate =0 end
            local data = {windowlist[i].name,windowlist[i].layer, duplicate}
            config:set('APPS', 'apps_'..i, data)
        end
    end 

    for i=1 ,#layerList do 
        if layerList[i] ~= nil then 
            config:set('LAYER_'..i,'uioffsetx',layerList[i].uioffsetx)
            config:set('LAYER_'..i,'uioffsety',layerList[i].uioffsety)
            config:set('LAYER_'..i,'uioffsetz',layerList[i].uioffsetz)
            config:set('LAYER_'..i,'rotationx',layerList[i].rotationx)
            config:set('LAYER_'..i,'rotationy',layerList[i].rotationy)
            config:set('LAYER_'..i,'rotationz',layerList[i].rotationz)
            config:set('LAYER_'..i,'uisize',layerList[i].uisize)
            config:set('LAYER_'..i,'opacity',layerList[i].opacity)
            config:set('LAYER_'..i,'brightness',layerList[i].brightness)
            config:set('LAYER_'..i,'apps',layerList[i].apps)
        end
    end
    local filename
    if name ~= nil then 
        filename = ac.getFolder(ac.FolderID.ScriptConfig)..'_config__'..name..'.ini'
    else
        filename = ac.getFolder(ac.FolderID.ScriptConfig)..'_config__default.ini'
    end 
    config:save(filename)

    local maxIndex
    local exists = false
    local setval = nil
    for index,key in configNames:iterateValues('CONFIGS','config',true) do
        if configNames:get('CONFIGS',key,"name") == name then 
            exists = true 
            setval = string.gsub(key,'config_','')
            break
        end
        maxIndex = index
    end
    if not exists then 
        configNames:set('CONFIGS','config_'..maxIndex,name)
        setval = maxIndex
    end
    configNames:set('SELECTED','select',setval)
    selectedSetting = configNames:get('CONFIGS','config_'..setval,"name")
    configNames:save()

    ac.debug('storage',configNames)
end 

function loadSettings(name)
    local filename
    if name ~= nil then 
        filename = ac.getFolder(ac.FolderID.ScriptConfig)..'_config__'..name..'.ini'
    else
        filename = ac.getFolder(ac.FolderID.ScriptConfig)..'_config__default.ini'
    end 
    config = ac.INIConfig.load(filename,ac.INIFormat.Extended)
    ac.debug('configName',filename)
    ac.debug('config',config)
    for index , section in config:iterate('LAYER') do
        local layerNumSt = string.gsub(section,'LAYER_','')
        local layerNum = tonumber(layerNumSt)
        local layer_in = {
            layer = layerNum , pos = windowSize ,size = vec2(0,0),obs = false 
            ,layerSize = vec2(0,0)
            ,uioffsetx = config:get(section,'uioffsetx',0)
            ,uioffsety = config:get(section,'uioffsety',0)
            ,uioffsetz = config:get(section,'uioffsetz',0)
            ,rotationx = config:get(section,'rotationx',0)
            ,rotationy = config:get(section,'rotationy',0)
            ,rotationz = config:get(section,'rotationz',0)
            ,uisize = config:get(section,'uisize',0)
            ,brightness = config:get(section,'brightness',0)
            ,opacity = config:get(section,'opacity',0)
            ,visible = false
            ,apps=config:get(section,'apps',{}) }
        --table.insert(layer_in.apps, windowlist[i].name)
        layerList[layerNum] = layer_in
    end
    for index,key in config:iterateValues('APPS','apps',true) do
        local appData = config:get('APPS',key,{name='name',layer=0,dup=false})
        local accesser = ac.accessAppWindow(appData[1])
        local dup = false
        if tonumber(appData[3]) == 1 then dup = true end
        accesser:setRedirectLayer(tonumber(appData[2]),dup)
    end
    local setval = nil
    for index,key in configNames:iterateValues('CONFIGS','config',true) do
        if configNames:get('CONFIGS',key,"name") == name then 
            setval = string.gsub(key,'config_','')
            break
        end
    end
    configNames:set('SELECTED','select',setval)
    configNames:save()
end
