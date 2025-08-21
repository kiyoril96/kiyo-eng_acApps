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
        local s = math.sin(math.lerp(-1,1, i / meeter) * math.pi)
        local c = -math.cos(math.lerp(-1,1, i / meeter) * math.pi)

        if (i>=0 and i <= 10) or (i>=30 and i <= 40) then 
            ui.drawLine(center + vec2(s, c) * 350, center + vec2(s, c) * 400, rgbm(0.2,0.2,1,1), 70)
        else
            ui.drawLine(center + vec2(s, c) * 380, center + vec2(s, c) * 399, rgbm(0.2,0.2,1,1),1)
        end
    end
    ui.endRotation(45)

    --ui.drawRectFilled(vec2(0, 400), vec2(30,410),rgbm(1,1,1,1))
    --ui.beginRotation()
    --ui.drawRectFilled(vec2(0, 100), vec2(300,400),rgbm(1,1,1,1))
    --ui.endPivotRotation(180,vec2(400,400))
end)
canvas:setName('scriptTexture')

tex1 = canvas

local vr_state = nil
local vrPos = nil
local vrSide = nil
local vrUp = nil
local vrLook = nil
local vrHorizon = nil
local vrHrizonLook = nil
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
local point_right_side = vec3()
local debug = 1

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
        vrHrizonLook = math.cross(vrSide,worldUp):normalize()

        offset:set(
            vrSide*offset_x
            +vrUp*offset_y
            +vrLook*offset_z
        )
        center:set(vrPos+offset)
        point_left = center +  ( vrSide*(ipd/2))
        point_right = center + ( vrSide*-(ipd/2))
        
        point_left_side = point_left +  ( vrSide*0.05) + (vrLook*-0.007) 
        point_right_side = point_right + ( vrSide*-0.05) + (vrLook*-0.007)


        local p1 = point_left +  (-vrHorizon*size)
        local p2 = point_left +  (worldUp*size)
        local p3 = point_left +  (vrHorizon*size)
        local p4 = point_left +  (-worldUp*size)
        local p5 = point_right + (-vrHorizon*size)
        local p6 = point_right + (worldUp*size)
        local p7 = point_right + (vrHorizon*size)
        local p8 = point_right + (-worldUp*size)

        local p9 = point_left_side +  (-vrHrizonLook*size)
        local p10 = point_left_side +  (worldUp*size)
        local p11 = point_left_side +  (vrHrizonLook*size)
        local p12 = point_left_side +  (-worldUp*size)
        local p13 = point_right_side + (-vrHrizonLook*size)
        local p14 = point_right_side + (worldUp*size)
        local p15 = point_right_side + (vrHrizonLook*size)
        local p16 = point_right_side + (-worldUp*size)

        render.quad(p1,p2,p3,p4,rgbm(10,10,10,0.02),canvas)
        render.quad(p5,p6,p7,p8,rgbm(10,10,10,0.02),canvas)
        render.quad(p9,p10,p11,p12,rgbm(10,10,10,0.02),canvas)
        render.quad(p13,p14,p15,p16,rgbm(10,10,10,0.02),canvas)

        if debug then 
            render.debugText(p1,'p1',rgbm(1,1,1,1),0.5)
            render.debugText(p2,'p2',rgbm(1,1,1,1),0.5)
            render.debugText(p3,'p3',rgbm(1,1,1,1),0.5)
            render.debugText(p4,'p4',rgbm(1,1,1,1),0.5)
            render.debugText(p5,'p5',rgbm(1,1,1,1),0.5)
            render.debugText(p6,'p6',rgbm(1,1,1,1),0.5)
            render.debugText(p7,'p7',rgbm(1,1,1,1),0.5)
            render.debugText(p8,'p8',rgbm(1,1,1,1),0.5)
            render.debugText(p9,'p9',rgbm(1,1,1,1),0.5)
            render.debugText(p10,'p10',rgbm(1,1,1,1),0.5)
            render.debugText(p11,'p11',rgbm(1,1,1,1),0.5)
            render.debugText(p12,'p12',rgbm(1,1,1,1),0.5)
            render.debugText(p13,'p13',rgbm(1,1,1,1),0.5)
            render.debugText(p14,'p14',rgbm(1,1,1,1),0.5)
            render.debugText(p15,'p15',rgbm(1,1,1,1),0.5)
            render.debugText(p16,'p16',rgbm(1,1,1,1),0.5)

            render.circle(point_left,vrLook,0.002,rgbm(1,0,0,1))
            render.circle(point_right,vrLook,0.002,rgbm(0,0,1,1))

            render.circle(point_left_side,vrSide,0.002,rgbm(1,0,0,1))
            render.circle(point_right_side,vrSide,0.002,rgbm(0,0,1,1))
        end

    end 
end

function update()
    
end 