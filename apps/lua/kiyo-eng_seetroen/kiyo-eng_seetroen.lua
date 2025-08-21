--local texture = class('texture')
--
--texture.fields = 'test'
--
--function texture:update()
--
--end
local sqrt = math.sqrt(2)
local canvas = ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R8G8B8A8.SNorm,render.TextureFlags.None)
canvas:update(function ()
    local center = vec2(400,400)
    ui.beginRotation()
    local meeter = 40
    local line = meeter/4
    --local big_meeter = meeter/5
    for i = 0, meeter do 
        local s = math.sin(math.lerp(-1, 1, i / meeter) * math.pi)
        local c = -math.cos(math.lerp(-1, 1, i / meeter) * math.pi)
        if i%line==0 then
            ui.drawLine(center, center + vec2(s, c) * (400*sqrt), rgbm(255,255,255,1), 3)
        --elseif i%big_meeter == 0 then 
        --    ui.drawLine(center + vec2(s, c) * 370, center + vec2(s, c) * 400, rgbm(255,255,255,1), 3)
        else
            ui.drawLine(center + vec2(s, c) * 380, center + vec2(s, c) * 399, rgbm(255,255,255,1),1)
        end
    end
    ui.endRotation(45)
end)
canvas:setName('scriptTexture')

tex1 = canvas

local vr_state = nil
local vrPos = nil
local vrSide = nil
local vrUp = nil
local vrLook = nil
local vrHorizon = nil
local worldUp = nil
local offset_x =nil
local offset_y =nil
local offset_z =nil
local offset = vec3()
local size = 0.04
local center = vec3()
local ipd = 60*0.001
local point_left = vec3()
local point_right = vec3()
local point_left_side = vec3()
local point_left_side = vec3()
local debug = false

function draw3dui(dt)
    --texture:update()
    if debug or ac.getSim().isVRConnected then 

        if debug then
            vrPos = ac.getCar(0).position
            vrSide = ac.getCar(0).side
            vrUp = ac.getCar(0).up
            vrLook = ac.getCar(0).look

            offset_x = 0.345
            offset_y = 1
            offset_z = -0.32
        else 
            vr_state = ac.getVR()
            vrPos = vr_state.headTransform.position
            vrSide = vr_state.headTransform.side
            vrUp = vr_state.headTransform.up
            vrLook = vr_state.headTransform.look

            offset_x = 0
            offset_y = 0
            offset_z = -0.055
        end
        
        worldUp = vec3(0,1,0)
        vrHorizon = math.cross(vrLook,worldUp):normalize()

        offset:set(
            vrSide*offset_x
            +vrUp*offset_y
            +vrLook*offset_z
        )
        center:set(vrPos+offset)
        point_left = center +  ( vrSide*(ipd/2))
        point_right = center + ( vrSide*-(ipd/2))

        local p1 = point_left +  (-vrHorizon*size)
        local p2 = point_left +  (worldUp*size)
        local p3 = point_left +  (vrHorizon*size)
        local p4 = point_left +  (-worldUp*size)
        local p5 = point_right + (-vrHorizon*size)
        local p6 = point_right + (worldUp*size)
        local p7 = point_right + (vrHorizon*size)
        local p8 = point_right + (-worldUp*size)

        render.quad(p1,p2,p3,p4,rgbm(10,10,10,1),canvas)
        render.quad(p5,p6,p7,p8,rgbm(10,10,10,1),canvas)

        --render.quad()
        render.debugText(p1,'p1',rgbm(1,1,1,1),1)
        render.debugText(p2,'p2',rgbm(1,1,1,1),1)
        render.debugText(p3,'p3',rgbm(1,1,1,1),1)
        render.debugText(p4,'p4',rgbm(1,1,1,1),1)
        render.debugText(p5,'p5',rgbm(1,1,1,1),1)
        render.debugText(p6,'p6',rgbm(1,1,1,1),1)
        render.debugText(p7,'p7',rgbm(1,1,1,1),1)
        render.debugText(p8,'p8',rgbm(1,1,1,1),1)

        --render.circle(point_left,vrLook,0.005,rgbm(1,0,0,1))
        --render.circle(point_right,vrLook,0.005,rgbm(0,0,1,1))

        ac.debug('p1',p1)
        ac.debug('p2',p2)
        ac.debug('p3',p3)
        ac.debug('p4',p4)
        ac.debug('p5',p5)
        ac.debug('p6',p6)
        ac.debug('p7',p7)
        ac.debug('p8',p8)

        --ac.debug('con',vr_state.isVRConnected)

    end 
end

function update()
    
end 