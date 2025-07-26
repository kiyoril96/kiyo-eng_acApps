local windowSize = ac.getSim().windowSize

--local uioffsetx = 0.6
--local uioffsety = 0.2
--local uioffsetz = -0.25
--local uisize=0.1

local pos
local up
local side
local look

local rotationx = 0
local rotationy = 0
local rotationz = 0

local p1
local p2
local p3
local p4

-- Debug用
local visible = false
local pointSize = 0.01
local colerCenter = rgbm(0,0,0,1) -- 黒
local colerP1 = rgbm(100,0,0,1) -- 赤
local colerP2 = rgbm(0,100,0,1) -- 青
local colerP3 = rgbm(0,0,100,1) -- 緑
local colerP4 = rgbm(100,100,100,1) -- 白

-- アプリレイヤーの一覧
local layerList = {}
local windowlist = {}

-- 空間にUI用のポリゴンを用意して描画する（位置決めとか）
-- RENDER_CALLBACKS で呼ぶ
function draw3dui()
    -- 車両との相対座標を算出
    pos = ac.getCar(0).position
    up = ac.getCar(0).up
    side = ac.getCar(0).side
    look = ac.getCar(0).look

    for i = 1 , #layerList  do
        if #layerList[i].apps~=0 then
            -- ここでは表示だけやる

            -- TODO ちゃんとつくる
            local center = pos+vec3(0,layerList[i].uioffsety,0)+(side*-layerList[i].uioffsetx)+(look*-layerList[i].uioffsetz)

            -- UIの向きを変える
            -- lookの向きから変えないと後段の回転軸がよくわからなくなる
            local look = vec3(look.x,look.y,look.z):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationx),up)):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationy),side))
            local side = vec3(side.x,side.y,side.z):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationx),up)):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationz),look))
            local up = vec3(up.x,up.y,up.z):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationy),side)):rotate(quat.fromAngleAxis(math.radians(layerList[i].rotationz),look))

            -- 4点の位置を決める（正方形）
            local p1 = (center+(side*layerList[i].uisize * ((layerList[i].layerSize.x/2)/(layerList[i].layerSize.y/2)) )+(up*layerList[i].uisize *((layerList[i].layerSize.y/2)/(layerList[i].layerSize.x/2)) ))
            local p2 = (center+(side*-layerList[i].uisize* ((layerList[i].layerSize.x/2)/(layerList[i].layerSize.y/2)) )+(up*layerList[i].uisize *((layerList[i].layerSize.y/2)/(layerList[i].layerSize.x/2)) ))
            local p3 = (center+(side*-layerList[i].uisize* ((layerList[i].layerSize.x/2)/(layerList[i].layerSize.y/2)) )+(up*-layerList[i].uisize*((layerList[i].layerSize.y/2)/(layerList[i].layerSize.x/2)) ))
            local p4 = (center+(side*layerList[i].uisize * ((layerList[i].layerSize.x/2)/(layerList[i].layerSize.y/2)) )+(up*-layerList[i].uisize*((layerList[i].layerSize.y/2)/(layerList[i].layerSize.x/2)) ))
            -- TODO ここまで

            render.quad(p1,p2,p3,p4,rgbm(10,10,10,1),layerList[i].appCanvas)

                -- 確認用
            if layerList[i].visible then 
                render.circle(center,look,pointSize,colerCenter,nil)
                render.circle(p1,look,pointSize,colerP1,nil)
                render.circle(p2,look,pointSize,colerP2,nil)
                render.circle(p3,look,pointSize,colerP3,nil)
                render.circle(p4,look,pointSize,colerP4,nil)
            end
        end
    end
end

-- アプリが転送されたレイヤーの表示位置等を調整するUI
function layer3DController()

    ui.columns(6)
    ui.dwriteText('Layer')
    ui.nextColumn()
    ui.dwriteText('Position')
    ui.nextColumn()
    ui.dwriteText('Rotation')
    ui.nextColumn()
    ui.dwriteText('DebugPoint')
    ui.nextColumn()
    ui.dwriteText('Coler')
    ui.nextColumn()
    ui.dwriteText('OBS')
    ui.nextColumn()
    
    for i=1,#layerList do

        if #layerList[i].apps ~= 0 then 

            ui.dwriteText(i)
            ui.nextColumn()

            -- 位置調整
            local value,changed = ui.slider('##uioffsetx'..i, layerList[i].uioffsetx, -1, 1, 'OFFSETX: %.03f')
            if changed then layerList[i].uioffsetx = value end
            local value,changed = ui.slider('##uioffsety'..i, layerList[i].uioffsety, -1, 1, 'OFFSETY: %.03f')
            if changed then layerList[i].uioffsety = value end
            local value,changed = ui.slider('##uioffsetz'..i, layerList[i].uioffsetz, -1, 1, 'OFFSETZ: %.03f')
            if changed then layerList[i].uioffsetz = value end
            local value,changed = ui.slider('##isize'..i, layerList[i].uisize, 0, 1, 'SIZE: %.02f')
            if changed then layerList[i].uisize = value end
            
            ui.nextColumn()

            -- 回転
            local value,changed = ui.slider('##rotationx'..i, layerList[i].rotationx, -90, 90, 'ROTATIONX: %.0f')
            if changed then layerList[i].rotationx = value end
            local value,changed = ui.slider('##rotationy'..i, layerList[i].rotationy, -90, 90, 'ROTATIONY: %.0f')
            if changed then layerList[i].rotationy = value end
            local value,changed = ui.slider('##rotationz'..i, layerList[i].rotationz, -90, 90, 'ROTATIONZ: %.0f')
            if changed then layerList[i].rotationz = value end

            ui.nextColumn()

            -- 確認用のポイントを表示
            if ui.checkbox('Debug Point'..i, layerList[i].visible) then
                layerList[i].visible = not  layerList[i].visible
            end

            ui.nextColumn()

            -- coler

            ui.nextColumn()

            -- obs

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

-- 3d表示、複製を制御するUI
function redirectSelecter()
    windowlist = ac.getAppWindows()
    ui.columns(3)
    ui.dwriteText('Windww')
    ui.nextColumn()
    ui.dwriteText('Redirect Layer')
    ui.nextColumn()
    ui.dwriteText('Duplicate')
    ui.nextColumn()

    -- For 入れ子はちょっとパフォーマンスに問題ありか…？
    -- ↑ まあ表示してる間だけの処理だし...
    for i = 1 ,#windowlist do
        -- 表示されていないアプリと自分自身を除く
        if windowlist[i].visible and windowlist[i].name ~= 'IMGUI_LUA_kiyo-eng_3d_redirect_app_main' and windowlist[i].name ~= nil then 
            ui.dwriteText( nonblank( windowlist[i].title, windowlist[i].name )  ) 
            ui.nextColumn()
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
                            ,uioffsetx = 0.2 ,uioffsety = 0.2 ,uioffsetz = 0
                            ,rotationx = 0 ,rotationy = 0 ,rotationz = 0
                            ,uisize = 0.1
                            ,visible = false
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

    ac.debug('key',#layerList)
end
