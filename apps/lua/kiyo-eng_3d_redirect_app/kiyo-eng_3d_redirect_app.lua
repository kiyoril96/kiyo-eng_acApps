-- canvas の用意
local canvas=ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R16G16B16A16.Float,render.TextureFlags.Shared)
local canvas2=ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R16G16B16A16.Float,render.TextureFlags.Shared)
canvas:setName('testTexture') -- 名前を付ければLua debugで見えるようになるらしい
canvas2:setName('testView')
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
    local windowSize = ac.getSim().windowSize
    local accsesser =ac.accessAppWindow('Sidekick'):setRedirectLayer(2,true)
    local appPos = accsesser:position()
    local appSize = accsesser:size()
    local appCenter = appPos+(vec2(appSize.x/2,appSize.y/2))

    local uv1 = vec2( math.max(0,(appCenter-(vec2(400,400))).x/windowSize.x) , math.max(0,(appCenter - (vec2(400,400))).y /windowSize.y))
    --local uv2 = vec2( 1,1)
    -- local uv1 = vec2((appPos.x/windowSize.x),(appPos.y/windowSize.y))
    -- local uv2 = vec2((800/windowSize.x),(800/windowSize.y))
    
    
    ac.debug('windowSize',windowSize)
    ac.debug('appPos',appPos)
    ac.debug('appSize',appSize)
    ac.debug('appCenter',appCenter)
    ac.debug('uv1',uv1)
    ac.debug('uv2',uv2)

    ui.drawCircle(appCenter,3,rgbm(1,0,0,1))
    canvas:clear()
    canvas:updateWithShader({
            p1 = vec2(0,0),
            p2 = windowSize,
            uv1 = uv1,
            --uv2 = uv2,
            textures = {tx1 = 'dynamic::hud::redirected::2'},
            shader = [[
                float4 main(PS_IN pin){
                    float4 ret = tx1.Sample(samLinear,pin.Tex);
                    return float4(ret.rgba);
                }]]
    })
end
