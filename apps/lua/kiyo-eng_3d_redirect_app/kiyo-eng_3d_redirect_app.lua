local windowSize = ac.getSim().windowSize

-- Debug用
local pointSize = 0.005
local colerCenter = rgbm(0,0,0,1) -- 黒
local colerP1 = rgbm(100,0,0,1) -- 赤
local colerP2 = rgbm(0,100,0,1) -- 緑
local colerP3 = rgbm(0,0,100,1) -- 青
local colerP4 = rgbm(100,100,100,1) -- 白

-- アプリレイヤーの一覧
local layerList = {}
local windowlist = {}

local pos = nil
local eyePos = nil
local center =nil
local radx =nil
local rady =nil
local radz =nil
local look =nil
local side =nil
local up =nil
local uiscale =nil
local p1 =nil
local p2 =nil
local p3 =nil
local p4 =nil


-- RENDER_CALLBACKS
function draw3dui(dt)

    up = ac.getCar(0).up
    side = ac.getCar(0).side
    look = ac.getCar(0).look
    eyePos = ac.getCar(0).driverEyesPosition
    pos = ac.getCar(0).position + ( side*eyePos.x + up*eyePos.y + look*eyePos.z -look*eyePos.z)

    for i = 1 , #layerList  do
        if #layerList[i].apps~=0 then
            -- ここでは表示だけ
            local center = pos+(up*layerList[i].uioffsety)+(side*-layerList[i].uioffsetx)+(look*layerList[i].uioffsetz)
            
            -- UIの向きを変える
            local radx = math.radians(layerList[i].rotationx)
            local rady = math.radians(layerList[i].rotationy)
            local radz = math.radians(layerList[i].rotationz)
            -- lookの向きから変えないと後段の回転軸がよくわからなくなる
            local look = vec3(look.x,look.y,look.z):rotate(quat.fromAngleAxis(rady,up)):rotate(quat.fromAngleAxis(radx,side))
            local side = vec3(side.x,side.y,side.z):rotate(quat.fromAngleAxis(rady,up)):rotate(quat.fromAngleAxis(radz,look))
            local up = vec3(up.x,up.y,up.z):rotate(quat.fromAngleAxis(radx,side)):rotate(quat.fromAngleAxis(radz,look))

            uiscale = (layerList[i].appCanvas:size():normalize()*layerList[i].uisize)
            p1 = center + (side*(uiscale.x)) + (up*(uiscale.y))            
            p2 = center + (-side*(uiscale.x)) + (up*(uiscale.y))
            p3 = center + (-side*(uiscale.x)) + (-up*(uiscale.y))
            p4 = center + (side*(uiscale.x)) + (-up*(uiscale.y))

            render.quad(p1,p2,p3,p4,rgbm(layerList[i].brightness,layerList[i].brightness,layerList[i].brightness,layerList[i].opacity),layerList[i].appCanvas)

            -- 確認用
            if layerList[i].visible then 
                render.circle(center,look,pointSize,colerCenter,nil)
                render.circle(p1,look,pointSize,colerP1,nil)
                render.circle(p2,look,pointSize,colerP2,nil)
                render.circle(p3,look,pointSize,colerP3,nil)
                render.circle(p4,look,pointSize,colerP4,nil)
                render.debugText(center,tostring(i),colerP4,render.FontAlign.Center)
            end
        end
    end
end

-- アプリが転送されたレイヤーの表示位置等を調整するUI
local contorollerInit = false
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
        if #layerList[i].apps ~= 0 then 
            -- layer num
            ui.dwriteText(i)
            ui.nextColumn()
            -- position
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsetx'..i, layerList[i].uioffsetx, -1, 1, 'OFFSETX: %.03f')
            if changed then layerList[i].uioffsetx = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsety'..i, layerList[i].uioffsety, -1, 1, 'OFFSETY: %.03f')
            if changed then layerList[i].uioffsety = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uioffsetz'..i, layerList[i].uioffsetz, -1, 1, 'OFFSETZ: %.03f')
            if changed then layerList[i].uioffsetz = value end
            ui.offsetCursorY(10)
            ui.nextColumn()
            -- rotation
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##rotationx'..i, layerList[i].rotationx, -90, 90, 'ROTATIONX: %.0f')
            if changed then layerList[i].rotationx = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##rotationy'..i, layerList[i].rotationy, -90, 90, 'ROTATIONY: %.0f')
            if changed then layerList[i].rotationy = value end
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##rotationz'..i, layerList[i].rotationz, -90, 90, 'ROTATIONZ: %.0f')
            if changed then layerList[i].rotationz = value end
            ui.nextColumn()
            -- size
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##uisize'..i, layerList[i].uisize, 0, 1, 'SIZE: %.02f')
            if changed then layerList[i].uisize = value end
            -- brightness
            ui.setNextItemWidth(-0.1)
            local value,changed = ui.slider('##brightness'..i, layerList[i].brightness, 0, 100, 'BRIGHTNESS: %.0f')
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
local disableColor = rgbm(100,100,100,1)
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
                        -- んー・・・
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

        --ui.tabItem('Save and Load',function()
        --    ui.childWindow('saveAndLoad',ui.availableSpace(),function()
        --        ui.dwriteText('Save Settings',20)
        --        ui.dwriteText('Settings Name : ')
        --        ui.sameLine()
        --        ui.setNextItemWidth(-100)
        --        ui.inputText('SettingsName',settingName,ui.InputTextFlags.Placeholder,vec2(0,40))
        --        ui.sameLine()
        --        if ui.button('SAVE',vec2(50,40)) then
        --            saveSettings()
        --        end
        --        ui.offsetCursorY(30)
        --        ui.dwriteText('Load Settings',20)
        --        ui.dwriteText('Select Settings : ')
        --        ui.sameLine()
        --        ui.setNextItemWidth(-100)
        --        ui.combo('##settingsSelecter','label',function() 
        --            ui.selectable()
        --        end ) 
        --        ui.sameLine()
        --        if ui.button('LOAD',vec2(50,40)) then
        --            saveSettings()
        --        end
        --    end)
        --end)
    end)
end

function windowListReflesh()
end

function saveSettings()
    
end 

function getSettingsList()
    
end

function loadSettings()
end

-- UIの処理
-- 通常のコールバックかSIM_CALLBACKSで呼ぶ
function uiupdate()

    for i=1 ,#layerList do
        if #layerList[i].apps ~= 0 then
            -- layer.apps のアプリに対してPositionのMin、sizeのMaxを探す
            local minPos = windowSize*2
            local maxSizeVec = vec2(0,0)
            for l =0 , #layerList[i].apps do
                local window = ac.accessAppWindow(layerList[i].apps[l])
                if window then 
                    minPos = minPos:min(window:position())
                    maxSizeVec = maxSizeVec:max( window:position()+window:size())
                end 
            end
            local layerSize = maxSizeVec - minPos
            local canvas
            if layerSize ~= layerList[i].layerSize then 
                layerList[i].layerSize = layerSize
                if layerList[i].appCanvas then layerList[i].appCanvas:dispose() end
                canvas = ui.ExtraCanvas(layerSize,1,render.AntialiasingMode.None,render.TextureFormat.R8G8B8A8.SNorm,render.TextureFlags.None)
                canvas:setName('layer'..i)
            else 
                canvas = layerList[i].appCanvas
            end

            canvas:clear()
            canvas:updateWithShader({
                    --p1 = vec2(0,0),
                    p2 = windowSize,
                    uv1 = minPos/windowSize,
                    --uv2 = uv2,
                    textures = {tx1 = 'dynamic::hud::redirected::'..i},
                    shader = [[
                        float4 main(PS_IN pin){
                            float4 ret = tx1.Sample(samLinear,pin.Tex);
                            return float4(ret.rgba);
                        }]]
            })
            layerList[i].appCanvas = canvas
        else 
            -- TODO これがあるとなぜかやり直したときに真っ白になる 要調査
            if layerList[i].appCanvas then layerList[i].appCanvas:dispose() end 
        end

    end
    ac.debug('size', ac.accessAppWindow('IMGUI_LUA_kiyo-eng_3d_redirect_app_main'):size() )
end
