local up = nil
local side = nil
local look = nil
local eyePos = nil
local pos = nil
local center = nil 
local p1 = nil
local p2 = nil
local p3 = nil
local p4 = nil
local p5 = nil
local p6 = nil
local p7 = nil
local p8 = nil
local p9 = nil
local p10 = nil
local p11 = nil
local p12 = nil
local vel = nil

-- だいたい半径（m）
local size = 0.15
-- 小さいほうの半径
local harfSize = size/2
-- UI表示位置の調整用
local offset = vec3(0,-0.9,-0.08)
-- テクスチャ用の色
local coler = rgbm(10,10,10,0.5)

-- テクスチャを45度傾けるためにルート2
local sqrt = math.sqrt(2)

-- 加速度表示の暴れをちょっとだけ抑えてみる
local vel_smooth = {}

-- テクスチャ
--local tex1 = './tex1.png'
local canvas = ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R8G8B8A8.SNorm,render.TextureFlags.None)
canvas:update(function ()
    local center = vec2(400,400)
    -- それっぽい円
    --ui.drawCircle(center,394,rgbm(255,255,255,1),48,2)
    --ui.drawCircle(center,399,rgbm(255,255,255,1),48,2)

    -- それっぽい目盛
    -- 空間上で45度傾けて表示するためにテクスチャも傾ける
    ui.beginRotation()
    local meeter = 60
    local big_meeter = 5
    for i = 0, meeter do 
        local s = math.sin(math.lerp(-1, 1, i / meeter) * math.pi)
        local c = -math.cos(math.lerp(-1, 1, i / meeter) * math.pi)
        if i%big_meeter == 0 then 
            ui.drawLine(center + vec2(s, c) * 370, center + vec2(s, c) * 400, rgbm(255,255,255,1), 3)
        else
            ui.drawLine(center + vec2(s, c) * 380, center + vec2(s, c) * 399, rgbm(255,255,255,1),1)
        end
    end
    ui.endRotation(45)
end)
canvas:setName('scriptTexture')

tex1 = canvas


function gyro()

    local meeter = 60
    local big_meeter = 3
    for i = 0, meeter do 
        local s = math.sin(math.lerp(-1, 1, i / meeter) * math.pi)
        local c = -math.cos(math.lerp(-1, 1, i / meeter) * math.pi)
        render.glSetColor(rgbm():set(rgb(0.5,1,0.5)*100,1))
        render.glBegin(render.GLPrimitiveType.Lines)
        render.glVertex(center+(vec3(s,0,c)*size)-(vec3(0,1,0)*0.005))
        render.glVertex(center+(vec3(s,0,c)*size)+(vec3(0,1,0)*0.005))
        render.glVertex(center+(vec3(s,c,0)*size)-(vec3(0,0,1)*0.005))
        render.glVertex(center+(vec3(s,c,0)*size)+(vec3(0,0,1)*0.005))
        render.glVertex(center+(vec3(0,s,c)*size)-(vec3(1,0,0)*0.005))
        render.glVertex(center+(vec3(0,s,c)*size)+(vec3(1,0,0)*0.005))
        render.glEnd()
        
    end

    render.setBlendMode(render.BlendMode.AlphaBlend)
    render.glBegin(render.GLPrimitiveType.Lines)
    
    -- XYZ軸（ワールド座標）
    render.glSetColor(rgbm():set(rgb.colors.red*10,1))
    render.glVertex((center+vec3(-size,0,0)))
    render.glVertex((center+vec3(size,0,0)))
    
    render.glSetColor(rgbm():set(rgb.colors.green*10,1))
    render.glVertex((center+vec3(0,-size,0)))
    render.glVertex((center+vec3(0,size,0)))
    
    render.glSetColor(rgbm():set(rgb.colors.blue*10,1))
    render.glVertex((center+vec3(0,0,-size)))
    render.glVertex((center+vec3(0,0,size)))

    render.glSetColor(rgbm():set(rgb.colors.fuchsia*10,1))
    render.glVertex((center+(-side*harfSize)))
    render.glVertex((center+(side*harfSize)))
    
    render.glSetColor(rgbm():set(rgb.colors.yellow*10,1))
    render.glVertex((center+(-up*harfSize)))
    render.glVertex((center+(up*harfSize)))
    
    render.glSetColor(rgbm():set(rgb.colors.cyan*10,1))
    render.glVertex((center+(-look*harfSize)))
    render.glVertex(center+(look*harfSize))
    render.glEnd()

    render.glBegin(render.GLPrimitiveType.Quads)
    render.glSetColor(rgbm():set(rgb(0.5,1,0.5)*10,1))
    render.glTexture(tex1)
    render.glVertexTextured(p1,vec2(0,0))
    render.glVertexTextured(p2,vec2(0,1))
    render.glVertexTextured(p3,vec2(1,1))
    render.glVertexTextured(p4,vec2(1,0))
    
    render.glVertexTextured(p1,vec2(0,0))
    render.glVertexTextured(p5,vec2(0,1))
    render.glVertexTextured(p3,vec2(1,1))
    render.glVertexTextured(p6,vec2(1,0))
    
    render.glVertexTextured(p2,vec2(0,0))
    render.glVertexTextured(p5,vec2(0,1))
    render.glVertexTextured(p4,vec2(1,1))
    render.glVertexTextured(p6,vec2(1,0))
    
    render.glVertexTextured(p7, vec2(0,0))
    render.glVertexTextured(p8, vec2(0,1))
    render.glVertexTextured(p9, vec2(1,1))
    render.glVertexTextured(p10,vec2(1,0))
    
    render.glVertexTextured(p7, vec2(0,0))
    render.glVertexTextured(p11,vec2(0,1))
    render.glVertexTextured(p9, vec2(1,1))
    render.glVertexTextured(p12,vec2(1,0))
    render.glEnd()


    -- 中心点
    render.circle(center,look,size*0.02,rgbm.colors.black)
    -- 多分北？（Z軸＋）
    render.circle(center+vec3(0,0,size),look,size*0.03,rgbm():set(rgb.colors.red*255,1))
    -- 加速度表示 取得地が車両座標系のため絶対座標を算出
    local rerativeCenter = (-side*vel.x)+(up*vel.y)+(-look*vel.z)
    vel_smooth[#vel_smooth+1] = rerativeCenter
    
    render.debugArrow(center+(-look*0.05),center+(look*0.1),0.01,rgbm():set(rgb.colors.yellow*10,1))

    local vel_viiew = vec3()
    local smoothness = 10
    if #vel_smooth > smoothness then 
        table.remove(vel_smooth,#vel_smooth-smoothness)
        vel_viiew = vel_smooth[1]:lerp(vel_smooth[smoothness],0.5,vel_viiew)
    end

    render.setBlendMode(render.BlendMode.BlendPremultiplied)
    render.circle(center+vel_viiew,look,size*0.02,vel_viiew:length() > harfSize and rgbm():set(rgb((vel_viiew:length()*255),1,0)*255,255) or rgbm():set(rgb((vel_viiew:length()*255),1,0)*10,10))

    

end
    


local rad = 1/150
local flag = true
local rotLook= nil
local rotside= nil
local render_flg = false

function draw3dui(dt)

    up = ac.getCar(0).up
    side = ac.getCar(0).side
    look = ac.getCar(0).look
    eyePos = vec3(0,0,0) -- ac.getCar(0).driverEyesPosition
    pos = ac.getCar(0).position
    vel = ac.getCar(0).acceleration * harfSize

    local camlook = ac.getSim().cameraLook
    local camup = ac.getSim().cameraUp
    local camside = ac.getSim().cameraSide
    

    -- UI表示用 真ん中
    center = 
        (pos+ 
            (side*(eyePos.x - offset.x) 
            + up*(eyePos.y - offset.y) 
            + look*(eyePos.z+ offset.z))) 

    p1 = center + vec3((size*sqrt),0,0)
    p2 = center + vec3(0,0,(size*sqrt))
    p3 = center + vec3(-(size*sqrt),0,0)
    p4 = center + vec3(0,0,-(size*sqrt))
    p5 = center + vec3(0,(size*sqrt),0)
    p6 = center + vec3(0,-(size*sqrt),0)

    -- 小さいほう（車両座標系）の円
    p7 = center +  ( camside*(harfSize*sqrt))
    p8 = center +  ( camlook*(harfSize*sqrt))
    p9 = center +  (-camside*(harfSize*sqrt))
    p10 = center + (-camlook*(harfSize*sqrt))
    p11 = center + ( camup*(harfSize*sqrt))
    p12 = center + (-camup*(harfSize*sqrt))

    --gyro()

    --up = ac.getCar(0).up
    --side = ac.getCar(0).side
    --look = ac.getCar(0).look
    --eyePos = ac.getCar(0).driverEyesPosition
    ----eyePos= vec3(0,1,0)
    --pos = ac.getCar(0).position
    --vel = ac.getCar(0).acceleration * harfSize

    -- UI表示用 真ん中
    --center = (pos+ (side*(eyePos.x - offset.x) + up*(eyePos.y - offset.y) + look*eyePos.z -look*(eyePos.z+ offset.z))) 

    -- 大きい方（ワールド座標系）の円
    -- 45度傾けてる

    -- 外側の白い円弧
    --render.debugSphere(center,size,coler)
    
    --local ramielOffset = side*-0.3
    --
    --if rotLook== nil and rotside== nil then 
    --    rotLook = vec3():set(vec3(0,0,1)):rotate(quat.fromAngleAxis(rad,vec3(0,1,0)))
    --    rotside = vec3():set(vec3(1,0,0)):rotate(quat.fromAngleAxis(rad,vec3(0,1,0)))
    --end
--
    --rotLook = vec3():set(rotLook):rotate(quat.fromAngleAxis(rad,vec3(0,1,0)))
    --rotside = vec3():set(rotside):rotate(quat.fromAngleAxis(rad,vec3(0,1,0)))
--
    --p7  = center + (rotside*(harfSize))
    --p8  = center + (rotLook*(harfSize))
    --p9  = center +  (-rotside*(harfSize))
    --p10 = center + (-rotLook*(harfSize))
    --p11 = center + (vec3(0,1,0)*(harfSize))
    --p12 = center + (vec3(0,-1,0)*(harfSize))
--
    --render.setBlendMode(render.BlendMode.AlphaBlend)
    --render.glBegin(render.GLPrimitiveType.Quads)
    --render.glSetColor(rgbm():set(rgb(0,0,1)*50,0.1))
--
    --render.glVertex(p7 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p10 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glVertex(p10 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p9 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glVertex(p9 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p8 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
    --
    --render.glVertex(p8 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p7 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glEnd()
    --    
    --render.setBlendMode(render.BlendMode.Opaque)
    --render.glBegin(render.GLPrimitiveType.LinesStrip)
    --render.glSetColor(rgbm():set(rgb(0.6,0.6,1)*20,0.1))
--
    --render.glVertex(p7 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p10 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glVertex(p10 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p9 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glVertex(p9 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p8 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
    --
    --render.glVertex(p8 + ramielOffset)
    --render.glVertex(p11 + ramielOffset)
    --render.glVertex(p7 + ramielOffset)
    --render.glVertex(p12 + ramielOffset)
--
    --render.glVertex(p7 + ramielOffset)
    --render.glVertex(p8 + ramielOffset)
    --render.glVertex(p9 + ramielOffset)
    --render.glVertex(p10 + ramielOffset)
    -- render.glVertex(p7 + ramielOffset)
--
    --render.glEnd()

    
end



function update()
    --ac.debug('camlook',ac.getSim().cameraLook)
end