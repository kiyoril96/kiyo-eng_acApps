-- canvas の用意
local canvas=ui.ExtraCanvas(vec2(1920,1080),1,render.AntialiasingMode.None,render.TextureFormat.R16G16B16A16.Float,render.TextureFlags.Shared)
canvas:setName('testTexture') -- 名前を付ければLua debugで見えるようになるらしい
ac.debug('windows',ac.getAppWindows() )

local uioffsetx = 0.6
local uioffsety = 0.2
local uioffsetz = -0.25
local uisize=0.4

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
    p1 = (center+(side*uisize*(4/3))+(up*uisize*(3/4)))
    p2 = (center+(side*-uisize*(4/3))+(up*uisize*(3/4)))
    p3 = (center+(side*-uisize*(4/3))+(up*-uisize*(3/4)))
    p4 = (center+(side*uisize*(4/3))+(up*-uisize*(3/4)))

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
    local value,changed = ui.slider('##uioffsetx', uioffsetx, -2, 2, 'OFFSETX: %.02f')
    if changed then uioffsetx = value end
    local value,changed = ui.slider('##uioffsety', uioffsety, -2, 2, 'OFFSETY: %.02f')
    if changed then uioffsety = value end
    local value,changed = ui.slider('##uioffsetz', uioffsetz, -2, 2, 'OFFSETZ: %.02f')
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
        uioffsetx = 1.25
        uioffsety = 0.8
        uioffsetz = 1.2
        uisize=0.25
        rotationx = 0
        rotationy = 0
        rotationz = 0
    end 

    -- 確認用のポイントを表示
    if ui.checkbox('Debug Point',visible) then
        visible = not visible
    end
end
-- UIの処理
-- 通常のコールバックかSIM_CALLBACKSで呼ぶ
function uiupdate()
    -- canvas に描く
    canvas:clear()
    ac.accessAppWindow('PEDALS'):setRedirectLayer(1,true)
    ac.accessAppWindow('Sidekick'):setRedirectLayer(2,false)
    canvas:copyFrom('dynamic::hud::redirected::2')
    canvas:update(function(dt)
        -- 前のフレームで書いたものが残っているので削除
        end)
    
end
