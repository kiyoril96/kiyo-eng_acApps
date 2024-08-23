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
        if car.turningLightsActivePhase and car.turningLeftLights then 
            lcoler = colTurningLights
        end
        
        if car.turningLightsActivePhase and car.hazardLights
        then 
            hzcoler = colHazards
            lcoler = colTurningLights
            rcoler = colTurningLights
        end
        if car.turningLightsActivePhase and car.turningRightLights then
            rcoler = colTurningLights
        end

        ui.drawIcon(ui.Icons.TurnSignalLeft , vec2((size/4)-(iconsize/2),(iconsize/2)), vec2((size/4)+(iconsize/2),(iconsize*1.5)), lcoler)
        ui.drawIcon(ui.Icons.Hazard , vec2((size/2)-(iconsize/2),(iconsize/2)), vec2((size/2)+(iconsize/2),(iconsize*1.5)), hzcoler)
        ui.drawIcon(ui.Icons.TurnSignalRight , vec2((size/4*3)-(iconsize/2),(iconsize/2)), vec2((size/4*3)+(iconsize/2),(iconsize*1.5)), rcoler)
    end

    --car.hasLowBeams car.headlightsActive  car.lowBeams then
    
    if car.headlightsActive then
        if car.hasLowBeams and car.lowBeams then
            ui.drawCircleFilled(vec2((size)-(iconsize/2),(iconsize)),12,rgbm(1,1,1,1))
        else
            ui.drawCircleFilled(vec2((size)-(iconsize/2),(iconsize)),12,rgbm(1,1,0,1))
        end
    end

    if car.extraA then 
        ui.drawCircleFilled(vec2((size) ,(iconsize)),12,rgbm(1,0,0,1))
    end
    if car.extraB then
        ui.drawCircleFilled(vec2((size)+(iconsize/2),(iconsize)),12,rgbm(1,0,0,1))
    end  

end

function clocks()
    ui.dwriteDrawText(os.date("%H:%M:%S"),ui.availableSpaceY(),vec2(20,20))
end

local maxSpeed = 0
local viewMaxSpead = 0
local viewSpeed_brakerelece = 0
local view_bottomSpeed = 0
local viewed = false
local viewed_gas = false
function speedtracker()
    maxSpeed = math.max(ac.getCarSpeedKmh(),maxSpeed)
    if ac.getCar().brake > 0 then
        if not viewed then 
            viewMaxSpead = ac.getCarSpeedKmh()
            viewed = true
        end
        viewSpeed_brakerelece = ac.getCarSpeedKmh()
        maxSpeed = 0
    end

    if ac.getCar().gas > 0 then
        if not viewed_gas then
            view_bottomSpeed = ac.getCarSpeedKmh()
            viewed_gas = true
        end
    end
    
    if ac.getCar().brake <= 0 then viewed =false end
    if ac.getCar().gas <= 0 then viewed_gas =false end

    local viewtext = string.format("Brake On\t：%.02f\nBrake Off\t：%.02f\nGas On\t：%.02f",viewMaxSpead,viewSpeed_brakerelece,view_bottomSpeed) 
    ui.dwriteDrawText(viewtext,(ui.availableSpaceY()/3)-20 ,vec2(20,20))
    
end



function script.windowMain()
    car = ac.getCar()
    if ui.checkbox('Hold Mode',settings.isactive) then
        settings.isactive = not settings.isactive
    end
    local value,changed = ui.slider('##WipersMaxSpeed', wiperMax , 2, ac.getCar().wiperModes,'Wiper Min speed :  %.0f')
    if changed then wiperMax = value end

    local value2,changed2 = ui.slider('##MINSpeed', minspeed , 0, 5,'E-Brake Hold Threshold : %.02f km/h')
    if changed2 then 
        settings.minSpeed = value2
        minspeed = settings.minSpeed
    end
end

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
        ac.setExtraSwitch(0,not daytimelight)
        ac.setWiperMode(wiperMode)
        carInputs.brake = brake_hold
        carInputs.handbrake = handbrake_hold

        if car.velocity:length() <= (settings.minSpeed/3600*1000)  then 
            blakeHold()
        end
    end
end