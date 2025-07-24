-- canvas の用意
local canvas=ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R8G8B8A8.SNorm,render.TextureFlags.None)
canvas:setName('testTexture') -- 名前を付ければLua debugで見えるようになるらしい
ac.debug('windows',ac.getAppWindows() )

local uioffsetx = 0.6
local uioffsety = 0.2
local uioffsetz = -0.25
local uisize=0.1

local pos
local up
local side
local look

local center
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

-- 空間にUI用のポリゴンを用意して描画する（位置決めとか）
-- RENDER_CALLBACKS で呼ぶ
function draw3dui()
    -- 車両との相対座標を算出
    pos = ac.getCar(0).position
    up = ac.getCar(0).up
    side = ac.getCar(0).side
    look = ac.getCar(0).look

    -- UIの中心点を決める
    center = pos+vec3(0,uioffsety,0)+(side*-uioffsetx)+(look*-uioffsetz)

    -- UIの向きを変える
    -- lookの向きから変えないと後段の回転軸がよくわからなくなる
    look = vec3(look.x,look.y,look.z):rotate(quat.fromAngleAxis(math.radians(rotationx),up)):rotate(quat.fromAngleAxis(math.radians(rotationy),side))
    side = vec3(side.x,side.y,side.z):rotate(quat.fromAngleAxis(math.radians(rotationx),up)):rotate(quat.fromAngleAxis(math.radians(rotationz),look))
    up = vec3(up.x,up.y,up.z):rotate(quat.fromAngleAxis(math.radians(rotationy),side)):rotate(quat.fromAngleAxis(math.radians(rotationz),look))

    -- 4点の位置を決める（正方形）
    p1 = (center+(side*uisize)+(up*uisize))
    p2 = (center+(side*-uisize)+(up*uisize))
    p3 = (center+(side*-uisize)+(up*-uisize))
    p4 = (center+(side*uisize)+(up*-uisize))

    --3DUIの描画
    render.quad(p1,p2,p3,p4,rgbm(10,10,10,1),canvas)

    -- 確認用
    if visible then 
        render.circle(center,look,pointSize,colerCenter,nil)
        render.circle(p1,look,pointSize,colerP1,nil)
        render.circle(p2,look,pointSize,colerP2,nil)
        render.circle(p3,look,pointSize,colerP3,nil)
        render.circle(p4,look,pointSize,colerP4,nil)
    end

end

function windowMain()
    -- 位置調整    
    local value,changed = ui.slider('##uioffsetx', uioffsetx, -1, 1, 'OFFSETX: %.03f')
    if changed then uioffsetx = value end
    local value,changed = ui.slider('##uioffsety', uioffsety, -1, 1, 'OFFSETY: %.03f')
    if changed then uioffsety = value end
    local value,changed = ui.slider('##uioffsetz', uioffsetz, -1, 1, 'OFFSETZ: %.03f')
    if changed then uioffsetz = value end
    local value,changed = ui.slider('##uisize', uisize, 0, 1, 'SIZE: %.02f')
    if changed then uisize = value end

    -- 回転
    local value,changed = ui.slider('##rotationx', rotationx, -90, 90, 'ROTATIONX: %.0f')
    if changed then rotationx = value end
    local value,changed = ui.slider('##rotationy', rotationy, -90, 90, 'ROTATIONY: %.0f')
    if changed then rotationy = value end
    local value,changed = ui.slider('##rotationz', rotationz, -90, 90, 'ROTATIONZ: %.0f')
    if changed then rotationz = value end

    if ui.button('reset') then 
        uioffsetx = 0.6
        uioffsety = 0.2
        uioffsetz = -0.25
        uisize=0.1
        rotationx = 0
        rotationy = 0
        rotationz = 0
    end 

    -- 確認用のポイントを表示
    if ui.checkbox('Debug Point',visible) then
        visible = not visible
    end
end

function genlabel(num)
    local ret
    if num == 0 then ret = 'OFF' else ret = num end
    return ret
end

function nonblank(name1 ,name2) 
    if name1 == "" then return name2 else return name1 end  end


local layerList = {}
local windowlist = {}
function redirectConfig()
    windowlist = ac.getAppWindows()
    ui.columns(3)
    ui.dwriteText('Windww')
    ui.nextColumn()
    ui.dwriteText('Redirect Layer')
    ui.nextColumn()
    ui.dwriteText('Duplicate')
    ui.nextColumn()

    for i = 1 ,#windowlist do
        if windowlist[i].visible and windowlist[i].name ~= 'IMGUI_LUA_kiyo-eng_3d_redirect_app_config' and windowlist[i].name ~= nil then 
            ui.dwriteText( nonblank( windowlist[i].title, windowlist[i].name )  ) 
            ui.nextColumn()
            ui.combo('##layerSelecter'..i,genlabel(windowlist[i].layer),function() 
                -- 選択した数値のレイヤーへ転送する
                for y=0 , #layerList + 1  do 
                    if ui.selectable(genlabel(y)) then
                        local curlaer = ac.accessAppWindow(windowlist[i].name):redirectLayer(refbool(false))
                        if layerList[curlaer] ~= nil and layerList[curlaer].apps ~= nil then
                            table.removeItem( layerList[curlaer].apps, windowlist[i].name )
                        end
                        local layer_in = layerList[y] or {layer = y , pos = vec2(1,1),size = vec2(1,1),obs = true ,apps={} }
                        table.insert(layer_in.apps, windowlist[i].name)
                        ac.accessAppWindow(windowlist[i].name):setRedirectLayer(y,windowlist[i].layerDuplicate)
                        layerList[y] = layer_in

                    end 
                end
                
            end )
            ui.nextColumn()
            local dupStore = nil
            if ui.checkbox('##layerDuplicateSwitcher'..i,windowlist[i].layerDuplicate) and not dupStore then
                -- WindwoあくせさーのでゅぷりけーとをＯＮにする処理を呼ぶ
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
    -- canvas に描く
    local windowSize = ac.getSim().windowSize
    --local accsesser =ac.accessAppWindow('Sidekick'):setRedirectLayer(2,false)
    --local appPos = accsesser:position()
    --local appSize = accsesser:size()
    --local appCenter = appPos+(vec2(appSize.x/2,appSize.y/2))

    --local uv1 = vec2( (appCenter-(vec2(400,400))).x/windowSize.x , (appCenter - (vec2(400,400))).y /windowSize.y)
    -- local uv2 = vec2( 1,1)
    -- local uv1 = vec2((appPos.x/windowSize.x),(appPos.y/windowSize.y))
    -- local uv2 = vec2((800/windowSize.x),(800/windowSize.y))
    
    
    ac.debug('windowSize',windowSize)
    ac.debug('appPos',appPos)
    ac.debug('appSize',appSize)
    ac.debug('appCenter',appCenter)
    ac.debug('uv1',uv1)

    ac.debug('layers',layerList)
    ac.debug('curLayer',ac.accessAppWindow('CSPRSTATS'):redirectLayer(refbool(false)))
  
    
    
    --ui.drawCircle(appCenter,3,rgbm(1,0,0,1))
    --canvas:clear()
    --canvas:updateWithShader({
    --        --p1 = vec2(0,0),
    --        p2 = windowSize,
    --        uv1 = uv1,
    --        --uv2 = uv2,
    --        textures = {tx1 = 'dynamic::hud::redirected::2'},
    --        shader = [[
    --            float4 main(PS_IN pin){
    --                float4 ret = tx1.Sample(samLinear,pin.Tex);
    --                return float4(ret.rgba);
    --            }]]
    --})
end
