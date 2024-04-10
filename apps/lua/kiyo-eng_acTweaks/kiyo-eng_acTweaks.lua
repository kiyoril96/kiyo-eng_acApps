local car = nil
local config = nil
local light = false
local hb = false
local daytimelight = false
local wiperMode = 0
local wiperMax = -1
local minspeed = 5
local brake_hold = 0
local handbrake_hold = 0

local settings = ac.storage {
    isactive = true
    ,minSpeed = 5
}

local vrhudconfig = ac.INIConfig.load(ac.getFolder(ac.FolderID.ExtCfgUser)..'/vr_tweaks.ini')

local active = vrhudconfig:get('VR_HUD','ENABLED',true)

local move_with_first_view = vrhudconfig:get('VR_HUD','MOVE_WITH_FIRST_PERSON_CAMERA',true)
local move_with_camera =vrhudconfig:get('VR_HUD','MOVE_WITH_CAMERA',false)

local arch=vrhudconfig:get('VR_HUD','SHAPE_ARC',140) -- 80-160
local scale = vrhudconfig:get('VR_HUD','SHAPE_VERTICAL_SCALE',1.0) -- 0.6-1.4
local radius = vrhudconfig:get('VR_HUD','SHAPE_RADIUS',0.4) --0.2-1
local brightness =vrhudconfig:get('VR_HUD','BRIGHTNESS_MULT',1)--0-2

local base_offset = vrhudconfig:get('VR_HUD','BASE_OFFSET',vec3(0.0,0.0,0.0))
local cammera_offset=vrhudconfig:get('VR_HUD','CAMERA_OFFSET',vec3(0.0,0.0,0.0))

local render_mode = vrhudconfig:get('VR_HUD','RENDER_MODE',0) -- 0:Original or 1:See-Through or 2:X-Ray
local opacity = vrhudconfig:get('VR_HUD','RENDER_OCCLUDED_OPACITY') -- 0-1

function readSwitchState()
    config = ac.INIConfig.controlsConfig()
    if ac.isJoystickButtonPressed(config:get('ACTION_HEADLIGHTS','JOY',-1,1), config:get('ACTION_HEADLIGHTS','BUTTON',0,1)) then
        light = true
    else
        light = false
    end

    if ac.isJoystickButtonPressed(config:get('__EXT_LOW_BEAM','JOY',-1,1), config:get('__EXT_LOW_BEAM','BUTTON',0,1)) then
        light = true
        hb = true
    else
        light = light
        hb = false
    end

    if ac.isJoystickButtonPressed(config:get('__EXT_DAYTIME_LIGHT','JOY',-1,1), config:get('__EXT_DAYTIME_LIGHT','BUTTON',0,1)) then
        daytimelight = true
    else
        daytimelight = false
    end

    if ac.isJoystickButtonPressed(config:get('__EXT_DAYTIME_LIGHT','JOY',-1,1), config:get('__EXT_DAYTIME_LIGHT','BUTTON',0,1)) then
        daytimelight = true
    else
        daytimelight = false
    end

    if ac.isJoystickButtonPressed(config:get('__EXT_WIPERS_1','JOY',-1,1), config:get('__EXT_WIPERS_1','BUTTON',0,1)) then
        wiperMode = 1
    elseif ac.isJoystickButtonPressed(config:get('__EXT_WIPERS_4','JOY',-1,1), config:get('__EXT_WIPERS_4','BUTTON',0,1)) then
        wiperMode = wiperMax-1
    else
        wiperMode = 0
    end
end

function blakeHold()
    if ac.isJoystickButtonPressed(config:get('__EXT_HANDBRAKE_HOLD','JOY',-1,1), config:get('__EXT_HANDBRAKE_HOLD','BUTTON',0,1)) then
        if handbrake_hold < car.handbrake then
            brake_hold = car.brake
            handbrake_hold = car.handbrake
        end
    else
        if (handbrake_hold ~= 0 and handbrake_hold < car.handbrake) or (handbrake_hold == 1 and car.handbrake == handbrake_hold )then
            brake_hold = 0
            handbrake_hold = 0
        end
    end
end

local colTurningLights = rgbm(0.3, 1, 0.3, 1)
local colHazards = rgbm(1, 0.3, 0.3, 1)

function indicators()
    local size = ui.availableSpaceX()
    local iconsize = ac.getUiState().windowSize.x * 0.02

    if car.hasTurningLights then
        local lcoler = rgbm(1,1,1,1)
        local hzcoler = rgbm(1,1,1,1)
        local rcoler = rgbm(1,1,1,1)
        if car.turningLightsActivePhase and car.turningLeftLights then lcoler = colTurningLights end
        if car.turningLightsActivePhase and car.hazardLights
        then 
            hzcoler = colHazards
            lcoler = colTurningLights
            rcoler = colTurningLights
        end
        if car.turningLightsActivePhase and car.turningRightLights then rcoler = colTurningLights end

        ui.drawIcon(ui.Icons.TurnSignalLeft , vec2((size/4)-(iconsize/2),(iconsize/2)), vec2((size/4)+(iconsize/2),(iconsize*1.5)), lcoler)
        ui.drawIcon(ui.Icons.Hazard , vec2((size/2)-(iconsize/2),(iconsize/2)), vec2((size/2)+(iconsize/2),(iconsize*1.5)), hzcoler)
        ui.drawIcon(ui.Icons.TurnSignalRight , vec2((size/4*3)-(iconsize/2),(iconsize/2)), vec2((size/4*3)+(iconsize/2),(iconsize*1.5)), rcoler)
    end
end

function vrhudtweaks()
    
    if ui.checkbox('Active',active) then
        active = not active
        vrhudconfig:setAndSave('VR_HUD','ENABLED',active)
    end

    if ui.checkbox('MOVE_WITH_FIRST_PERSON_CAMERA', move_with_first_view) then
        move_with_first_view = not move_with_first_view
        vrhudconfig:setAndSave('VR_HUD','MOVE_WITH_FIRST_PERSON_CAMERA', move_with_first_view)
    end
    if ui.checkbox('MOVE_WITH_CAMERA',move_with_camera) then
        move_with_camera = not move_with_camera
        vrhudconfig:setAndSave('VR_HUD','MOVE_WITH_CAMERA',move_with_camera)
    end

    if active then
        local value,changed = ui.slider('SHAPE_ARC', arch , 80, 160,'%.02f')
        if changed then
            arch = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_ARC',arch)
        end
        local value,changed = ui.slider('SHAPE_VERTICAL_SCALE', scale , 0.6, 1.4,'%.02f')
        if changed then
            scale = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_VERTICAL_SCALE',scale)
        end
        local value,changed = ui.slider('SHAPE_RADIUS', radius , 0.2, 1.0,'%.02f')
        if changed then
            radius = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_RADIUS',radius)
        end
        local value,changed = ui.slider('BRIGHTNESS_MULT', brightness , 0, 2,'%.02f')
        if changed then
            brightness = value
            vrhudconfig:setAndSave('VR_HUD','BRIGHTNESS_MULT',brightness)
        end
        local value,changed = ui.slider('BASE_OFFSET_X', base_offset.x , -2, 2,'%.03f')
        if changed then
            base_offset.x = value
            vrhudconfig:setAndSave('VR_HUD','BASE_OFFSET',string.format("%.02f , %.02f , %.02f",base_offset.x,base_offset.y,base_offset.z))
        end
        local value,changed = ui.slider('BASE_OFFSET_Y', base_offset.y , -2, 2,'%.03f')
        if changed then
            base_offset.y = value
            vrhudconfig:setAndSave('VR_HUD','BASE_OFFSET',string.format("%.02f , %.02f , %.02f",base_offset.x,base_offset.y,base_offset.z))
        end
        local value,changed = ui.slider('BASE_OFFSET_Z', base_offset.z , -2, 2,'%.03f')
        if changed then
            base_offset.z = value
            vrhudconfig:setAndSave('VR_HUD','BASE_OFFSET',string.format("%.02f , %.02f , %.02f",base_offset.x,base_offset.y,base_offset.z))
        end

        local value,changed = ui.slider('CAMERA_OFFSET_X', cammera_offset.x , -2, 2,'%.03f')
        if changed then
            cammera_offset.x = value
            vrhudconfig:setAndSave('VR_HUD','CAMERA_OFFSET',string.format("%.02f , %.02f , %.02f",cammera_offset.x,cammera_offset.y,cammera_offset.z))
        end
        local value,changed = ui.slider('CAMERA_OFFSET_Y', cammera_offset.y , -2, 2,'%.03f')
        if changed then
            cammera_offset.y = value
            vrhudconfig:setAndSave('VR_HUD','CAMERA_OFFSET',string.format("%.02f , %.02f , %.02f",cammera_offset.x,cammera_offset.y,cammera_offset.z))
        end
        local value,changed = ui.slider('CAMERA_OFFSET_Z', cammera_offset.z , -2, 2,'%.03f')
        if changed then
            cammera_offset.z = value
            vrhudconfig:setAndSave('VR_HUD','CAMERA_OFFSET',string.format("%.02f , %.02f , %.02f",cammera_offset.x,cammera_offset.y,cammera_offset.z))
        end

        if ui.radioButton('Original',render_mode==0) then
            render_mode = 0
        elseif ui.radioButton('See-Through',render_mode==1) then
            render_mode = 1
        elseif ui.radioButton('X-Ray',render_mode==2) then
            render_mode = 2
        end
        vrhudconfig:setAndSave('VR_HUD','RENDER_MODE',render_mode)
        
        if render_mode == 1 or render_mode == 2 then
            local value,changed = ui.slider('RENDER_OCCLUDED_OPACITY', opacity , 0,1,'%.02f')
            if changed then
                opacity = value
                vrhudconfig:setAndSave('VR_HUD','RENDER_OCCLUDED_OPACITY',opacity)
            end
        end
    end

end


function script.windowMain()
    car = ac.getCar()
    if ui.checkbox('Hold Mode',settings.isactive) then
        settings.isactive = not settings.isactive
    end
    local value,changed = ui.slider('Wipers Max Speed', wiperMax , 2, ac.getCar().wiperModes,'%.0f')
    if changed then wiperMax = value end

    local value2,changed2 = ui.slider('MIN Speed', minspeed , 1, 2,'%.0f')
    if changed2 then settings.minSpeed = value2 end
end

--function script.draw_test()
--    local uiState = ac.getUI()
--    render.rectangle(vec3(ac.getVR().headTransform.position)-vec3(ac.getVR().headTransform.look*0.2),ac.getVR().headTransform.look,0.3,0.3,rgbm(1,1,1,0.2))
--    ui.transparentWindow('helloWorldSpeedometer', uiState.windowSize - vec2(300, 280), vec2(200, 200), function ()
--        local car = ac.getCar(0)
--        local center = vec2(100, 100)
--        local markColor = rgbm(1, 1, 1, 0.3)
--        local markRedColor = rgbm(1, 0, 0, 0.7)
--        local needleColor = rgbm(1, 1, 1, 1)
--        ui.drawCircleFilled(center, 100, rgbm(0, 0, 0, 0.5), 40)
--    
--        for i = 0, 10 do 
--          local s = math.sin(math.lerp(-0.7, 0.7, i / 10) * math.pi)
--          local c = -math.cos(math.lerp(-0.7, 0.7, i / 10) * math.pi)
--          ui.drawLine(center + vec2(s, c) * 70, center + vec2(s, c) * 90, i > 7 and markRedColor or markColor, 1.5)
--        end
--    
--        for i = 0, 30 do 
--            if i % 3 ~= 0 then 
--            local s = math.sin(math.lerp(-0.7, 0.7, i / 30) * math.pi)
--            local c = -math.cos(math.lerp(-0.7, 0.7, i / 30) * math.pi)
--            ui.drawLine(center + vec2(s, c) * 80, center + vec2(s, c) * 90, i > 23 and markRedColor or markColor, 1)
--            end
--        end
--    
--        -- ui.text('speed:'..math.lerpInvSat(car.speedKmh, 0, 300))
--        local angle = math.lerp(-0.7, 0.7, math.lerpInvSat(car.rpm, 0, car.rpmLimiter * 1.2)) * math.pi
--        local s = math.sin(angle)
--        local c = -math.cos(angle)
--        ui.drawLine(center - vec2(s, c) * 20, center + vec2(s, c) * 95, needleColor, 1.5)
--    
--        ui.setCursor(vec2(0, 115))
--        ui.pushFont(ui.Font.Title)
--        ui.textAligned(string.format('%.0f', car.speedKmh), vec2(0.5, 0), vec2(200, 0))
--        ui.popFont()    
--    
--        ui.setCursor(vec2(0, 140))
--        ui.pushFont(ui.Font.Small)
--        ui.textAligned('km/h', vec2(0.5, 0), vec2(200, 0))
--        ui.popFont()
--    
--        ui.setCursor(vec2(0, 165))
--        ui.pushFont(ui.Font.Monospace)
--        ui.textAligned(string.format('%07.1f', car.distanceDrivenSessionKm), vec2(0.5, 0), vec2(200, 0))
--        ui.popFont()
--        end)
--end


function script.update(dt)
    car = ac.getCar()
    sim = ac.getSim()
    carInputs = ac.overrideCarControls(0)
    if wiperMax == -1 then wiperMax = car.wiperModes end

    if settings.isactive and sim.inputMode ~= 1 then
        readSwitchState()
        ac.setHeadlights(light)
        ac.setHighBeams(hb)
        ac.setDaytimeLights(daytimelight)
        ac.setWiperMode(wiperMode)
        carInputs.brake = brake_hold
        carInputs.handbrake = handbrake_hold

        if car.velocity:length() <= (settings.minSpeed/3600*1000)  then 
            blakeHold()
        end
    end

    ac.debug('scale',scale)
    ac.debug('move_with_camera',move_with_camera)
    ac.debug('render_mode',render_mode)
    ac.debug('brightness',brightness)
    ac.debug('opacity',opacity)
    ac.debug('cammera_offset',cammera_offset)
    ac.debug('arch',arch)
    ac.debug('move_with_first_view',move_with_first_view)
    ac.debug('base_offset',base_offset)
    ac.debug('radius',radius)
end