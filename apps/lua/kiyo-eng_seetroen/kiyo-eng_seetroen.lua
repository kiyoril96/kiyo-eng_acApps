local resetVars = {
    isActive = true
    ,isSideActive =true
    ,debug = false 
    ,size = 40
    ,ipd = 60
    ,offset_x = 0
    ,offset_y = 0
    ,offset_z = 0
    ,sideOffset_x = 50
    ,sideOffset_z = 0
    ,debugOffset_x = 0
    ,debugOffset_y = 0
    ,debugOffset_z = 0
} 

local settings = ac.storage {
    isActive = true
    ,isSideActive =true
    ,debug = false 
    ,size = 40
    ,ipd = 60
    ,offset_x = 0
    ,offset_y = 0
    ,offset_z = 0
    ,sideOffset_x = 50
    ,sideOffset_z = 0
    ,debugOffset_x = 0
    ,debugOffset_y = 0
    ,debugOffset_z = 0
}

function reset(varName)
    if varName == 'size' then settings.size = resetVars.size
    elseif varName == 'ipd' then settings.ipd = resetVars.ipd
    elseif varName == 'offset_x' then settings.offset_x = resetVars.offset_x
    elseif varName == 'offset_y' then settings.offset_y = resetVars.offset_y
    elseif varName == 'offset_z' then settings.offset_z = resetVars.offset_z
    elseif varName == 'sideOffset_x' then settings.sideOffset_x = resetVars.sideOffset_x
    elseif varName == 'sideOffset_z' then settings.sideOffset_z = resetVars.sideOffset_z
    elseif varName == 'debugOffset_x' then settings.debugOffset_x = resetVars.debugOffset_x
    elseif varName == 'debugOffset_y' then settings.debugOffset_y = resetVars.debugOffset_y
    elseif varName == 'debugOffset_z' then settings.debugOffset_z = resetVars.debugOffset_z
    end
end


local sqrt = math.sqrt(2)
local canvas = ui.ExtraCanvas(vec2(800,800),1,render.AntialiasingMode.None,render.TextureFormat.R8G8B8A8.SNorm,render.TextureFlags.None)
canvas:update(function ()
    local center = vec2(400,400)
    ui.beginRotation()
    local meeter = 40
    local line = meeter/4
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
end)
canvas:setName('scriptTexture')

local vr_state = nil
local vrPos = nil
local vrSide = nil
local vrUp = nil
local vrLook = nil
local vrHorizon = nil
local vrHrizonLook = nil
local worldUp = nil
local offset = vec3()
local center = vec3()
local point_left = vec3()
local point_right = vec3()
local point_left_side = vec3()
local point_right_side = vec3()

local p1 = vec3()
local p2 = vec3()
local p3 = vec3()
local p4 = vec3()
local p5 = vec3()
local p6 = vec3()
local p7 = vec3()
local p8 = vec3()
local p9 = vec3()
local p10 = vec3()
local p11 = vec3()
local p12 = vec3()
local p13 = vec3()
local p14 = vec3()
local p15 = vec3()
local p16 = vec3()


function drawSeetroen()
    -- ㎜ → m
    local offset_x = settings.offset_x*0.001
    local offset_y = settings.offset_y*0.001
    local offset_z = settings.offset_z*0.001
    local sideOffset_x = settings.sideOffset_x*0.001
    local sideOffset_z = settings.sideOffset_z*0.001
    local ipd = settings.ipd*0.001
    local size = settings.size*0.001

    if settings.debug then
        vrPos = ac.getCar(0).position
        vrSide = ac.getCar(0).side
        vrUp = ac.getCar(0).up
        vrLook = ac.getCar(0).look
        offset_x = settings.debugOffset_x + (settings.offset_x*0.001) 
        offset_y = settings.debugOffset_y + (settings.offset_y*0.001)
        offset_z = settings.debugOffset_z + (settings.offset_z*0.001)
    else 
        vr_state = ac.getVR()
        vrPos = vr_state.headTransform.position
        vrSide = vr_state.headTransform.side
        vrUp = vr_state.headTransform.up
        vrLook = vr_state.headTransform.look
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
    
    if settings.isSideActive then
        point_left_side = point_left +  ( vrSide*sideOffset_x) + (vrLook*-sideOffset_z) 
        point_right_side = point_right + ( vrSide*-sideOffset_x) + (vrLook*-sideOffset_z)
    end

    p1:set( point_left +  (-vrHorizon*size) )
    p2:set( point_left +  (worldUp*size) )
    p3:set( point_left +  (vrHorizon*size) )
    p4:set( point_left +  (-worldUp*size) )
    p5:set( point_right + (-vrHorizon*size) )
    p6:set( point_right + (worldUp*size) )
    p7:set( point_right + (vrHorizon*size) )
    p8:set( point_right + (-worldUp*size) )

    render.quad(p1,p2,p3,p4,rgbm(10,10,10,0.02),canvas)
    render.quad(p5,p6,p7,p8,rgbm(10,10,10,0.02),canvas)

    if settings.isSideActive then
        p9:set(point_left_side +  (-vrHrizonLook*size) )
        p10:set(point_left_side +  (worldUp*size) )
        p11:set(point_left_side +  (vrHrizonLook*size) )
        p12:set(point_left_side +  (-worldUp*size) )
        p13:set(point_right_side + (-vrHrizonLook*size) )
        p14:set(point_right_side + (worldUp*size) )
        p15:set(point_right_side + (vrHrizonLook*size) )
        p16:set(point_right_side + (-worldUp*size) )
    
        render.quad(p9,p10,p11,p12,rgbm(10,10,10,0.02),canvas)
        render.quad(p13,p14,p15,p16,rgbm(10,10,10,0.02),canvas)
    end

    if settings.debug then 
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



function draw3dui(dt)
    if settings.debug or ac.getSim().isVRConnected then 
        drawSeetroen()
    end 
end

function windowMain()
    ui.dwriteText('Activate')
    if ui.checkbox('Active',settings.isActive) then
        settings.isActive = not settings.isActive
    end
    ui.sameLine()
    if ui.checkbox('Side Active',settings.isSideActive) then
        settings.isSideActive = not settings.isSideActive
    end
    
    ui.dwriteText('UI Size (mm)')
    local value,changed = ui.slider('##uisize', settings.size, 5 , 60 , '%.0f')
    if changed then settings.size = value end
    ui.sameLine()
    if ui.smallButton(' R ##uisizereset') then reset('size') end

    ui.dwriteText('IPD (mm)')
    local value,changed = ui.slider('##ipd', settings.ipd, 10 , 80 , '%.02f')
    if changed then settings.ipd = value end
    ui.sameLine()
    if ui.smallButton(' R ##ipdreset') then reset('ipd') end

    ui.dwriteText('Offset (mm)')
    local value,changed = ui.slider('##offsetx', settings.offset_x, -100 , 100 , 'Horizontal : %.03f')
    if changed then settings.offset_x = value end
    ui.sameLine()
    if ui.smallButton(' R ##offsetxreset') then reset('offset_x') end

    local value,changed = ui.slider('##offsety', settings.offset_y, -100 , 100 , 'Upward : %.03f')
    if changed then settings.offset_y = value end
    ui.sameLine()
    if ui.smallButton(' R ##offsetyreset') then reset('offset_y') end

    local value,changed = ui.slider('##offsetz', settings.offset_z, -100 , 100 , 'Depth : %.03f')
    if changed then settings.offset_z = value end
    ui.sameLine()
    if ui.smallButton(' R ##offsetzreset') then reset('offset_z') end

    ui.dwriteText('Side Offset (mm)')
    local value,changed = ui.slider('##sideoffsetx', settings.sideOffset_x, -0 , 100 , 'Horizontal : %.03f')
    if changed then settings.sideOffset_x = value end
    ui.sameLine()
    if ui.smallButton(' R ##sideoffsetxreset') then reset('sideOffset_x') end

    local value,changed = ui.slider('##sideoffsetz', settings.sideOffset_z, -50 , 50 , 'Depth : %.03f')
    if changed then settings.sideOffset_z = value end
    ui.sameLine()
    if ui.smallButton(' R ##sideoffsetzreset') then reset('sideOffset_z') end

    ui.dwriteText('for Debug')
    if ui.checkbox('Debug',settings.debug) then
        settings.debug = not settings.debug
    end

    ui.dwriteText('Offset (mm)')
    local value,changed = ui.slider('##debugoffsetx', settings.debugOffset_x, -1 , 1 , 'Horizontal : %.03f')
    if changed then settings.debugOffset_x = value end
    ui.sameLine()
    if ui.smallButton(' R ##debugoffsetxreset') then reset('debugOffset_x') end

    local value,changed = ui.slider('##debugoffsety', settings.debugOffset_y, -1 , 1 , 'Upward : %.03f')
    if changed then settings.debugOffset_y = value end
    ui.sameLine()
    if ui.smallButton(' R ##debugoffsetyreset') then reset('debugOffset_y') end

    local value,changed = ui.slider('##debugoffsetz', settings.debugOffset_z, -1 , 1 , 'Depth : %.03f')
    if changed then settings.debugOffset_z = value end
    ui.sameLine()
    if ui.smallButton(' R ##debugoffsetzreset') then reset('debugOffset_z') end

end


function update()
    -- nop
end 