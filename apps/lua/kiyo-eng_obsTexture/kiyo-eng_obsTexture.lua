-- Access OBS helper library:
local obs = require('shared/utils/obs')
local sim
local car 
local cameraParameters = ac.storage{
  ccamactive = true
  , dashcamactive =true
  , cambercamactive =true
  , height = 1.7
  , pitch = 0
  , distance = 5 
  , fov =60
  , fps = 30
  , ccammaxangle =54
  , ccamSensiVel = 0.5
  , dashheight = 0
  , dashpitch = 0
  , dashdistance = 0
  , dashfov = 60
  , dashfps = 0
  , dashx = 0
  , dashy = 0
  , dashz = 0
  , dashroll =0
  , dashyaw =0
  , camberx = 0.1
  , cambery = -0.1
  , camberz = -0.4
  , camberfov = 60
}

local node = ac.findNodes('sceneRoot:yes')

local cpos
local cdir
local cup 
local cfov
local carVelocity = smoothing(vec3(), 40)
local lastCarPos = vec3()
local lookDirection = smoothing(0, 10)
function chaseCamera(dt)
  cfov = cameraParameters.fov
  local carTf = car.transform
  local carPos = vec3((car.wheels[0].position + car.wheels[1].position+car.wheels[2].position + car.wheels[3].position)/4)
  if lastCarPos ~= carPos then
    if lastCarPos ~= vec3() then
      local delta = lastCarPos - carPos      
      if #delta > 5 then delta = delta / #delta * 5 end
      carVelocity:update(-delta / dt)
    end
    lastCarPos = carTf.position
  end
  local carVelocityDir = math.normalize(carVelocity.val + carTf.look)
  local velocityX = math.clamp((math.dot(carTf.side, carVelocityDir) * ((#carVelocity.val)^cameraParameters.ccamSensiVel)) /5, -1, 1)
  local cameraAngle = velocityX * math.radians(cameraParameters.ccammaxangle)
  cameraAngle = cameraAngle + lookDirection.val * math.pi
  local sinAngle = math.sin(cameraAngle)
  local cosAngle = math.cos(cameraAngle)
  cpos = carTf:transformPoint(vec3(sinAngle*cameraParameters.distance,cameraParameters.height,-cosAngle*cameraParameters.distance))
  local cameraLookPosOffset = carTf.look + carTf.up * (1-math.abs(lookDirection.val))
  local cameraLook = (carTf.position + cameraLookPosOffset - cpos ):normalize()
  cdir = cameraLook:rotate(quat.fromAngleAxis(math.radians(-cameraParameters.pitch), carTf.side))
  cup = (carTf.up + vec3(0,2,0)):normalize()
end

local cshot
local ccam
obs.notify( function()
  ccam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'ChaserCamera' 
    ,obs.Flags.UserSize --+obs.Flags.ManualUpdate
    ,function (size)
      if cshot then cshot:dispose() end
      cshot = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      cshot:setBestSceneShotQuality()
    end, function (canvas)
      cshot:update(cpos,cdir,cup,cfov)
      canvas:updateWithShader({
        textures = { tx1 = cshot},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
    end)
end)

local dpos
local ddir
local dup
local dfov
function dashcamparam()
    local carTf = car.transform
    dpos = carTf:transformPoint(vec3(cameraParameters.dashx,cameraParameters.dashy,cameraParameters.dashz))
    ddir = carTf.look:rotate(quat.fromAngleAxis(math.radians(cameraParameters.dashyaw), carTf.up))
      :rotate(quat.fromAngleAxis(math.radians(cameraParameters.dashpitch), carTf.side))
    dup = carTf.up:rotate(quat.fromAngleAxis(math.radians(cameraParameters.dashroll), carTf.look))
      :rotate(quat.fromAngleAxis(math.radians(cameraParameters.dashroll), carTf.side))
    dfov = cameraParameters.dashfov
end

local dashcam
local dcam
obs.notify( function()
  dcam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'DashbordCamera' 
    ,obs.Flags.UserSize+obs.Flags.ManualUpdate
    ,function (size)
      if dashcam then dashcam:dispose() end
      dashcam = ac.GeometryShot(node, size, 1, true, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      dashcam:setClippingPlanes(0.01, 5e3)
      dashcam:setBestSceneShotQuality()
      end, function (canvas)
      dashcam:update(dpos,ddir,dup,dfov)
      canvas:updateWithShader({
        textures = { tx1 = dashcam},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
    end)
end)

local shootFL
local shootFR
local shootRL
local shootRR
local flcam
local frcam
local rlcam
local rrcam
local maxtravelF = 0
local maxtravelR = 0
obs.notify( function()
  flcam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'CAM-FL' 
    ,obs.Flags.UserSize+obs.Flags.ManualUpdate
    ,function (size)
      if shootFL then shootFL:dispose() end
      shootFL = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      shootFL:setBestSceneShotQuality()
    end, function (canvas)
      local wheel = car.wheels[0]
      local wheelPos = wheel.transform
      local camPos = wheelPos:transformPoint(vec3(cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootFL:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootFL},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
      canvas:update(function()
        if math.abs(wheel.suspensionTravel) > maxtravelF then maxtravelF = math.abs(wheel.suspensionTravel) end
        ui.drawLine(vec2(50,0),vec2(50,ui.availableSpaceY()),rgbm(0,0,0,1),7)
        ui.drawLine(vec2(100,ui.availableSpaceY()/2),vec2(0,ui.availableSpaceY()/2),rgbm(0,0,0,1),7)

        ui.drawCircleFilled(vec2(50,math.remap(wheel.suspensionTravel,maxtravelF*1.2,0,ui.availableSpaceY(),0) ),20,rgbm(1,1,1,1))
        ui.drawCircleFilled(vec2(50,math.remap(wheel.suspensionTravel,maxtravelF*1.2,0,0,ui.availableSpaceY()) ),20,rgbm(1,1,1,1))
        ac.debug('test_susTrav_FL',wheel.suspensionTravel)
        ac.debug('test_ExtraSusTrav_FL',physics.getExtendedDamperTravel(0,0))
      end)
    end
  )
  frcam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'CAM-FR' 
    ,obs.Flags.UserSize+obs.Flags.ManualUpdate
    ,function (size)
      if shootFR then shootFR:dispose() end
      shootFR = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      shootFR:setBestSceneShotQuality()
    end, function (canvas)
      local wheel = car.wheels[1]
      local wheelPos = wheel.transform
      local camPos = wheelPos:transformPoint(vec3(-cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootFR:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootFR},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
      canvas:update(function()
        if math.abs(wheel.suspensionTravel) > maxtravelF then maxtravelF = math.abs(wheel.suspensionTravel) end
        ui.drawLine(vec2(ui.availableSpaceX()-50,0),vec2(ui.availableSpaceX()-50,ui.availableSpaceY()),rgbm(0,0,0,1),7)
        ui.drawLine(vec2(ui.availableSpaceX()-100,ui.availableSpaceY()/2),vec2(ui.availableSpaceX(),ui.availableSpaceY()/2),rgbm(0,0,0,1),7)

        ui.drawCircleFilled(vec2(ui.availableSpaceX()-50,math.remap(wheel.suspensionTravel,maxtravelF*1.2,0,ui.availableSpaceY(),0) ),20,rgbm(1,1,1,1))
        ui.drawCircleFilled(vec2(ui.availableSpaceX()-50,math.remap(wheel.suspensionTravel,maxtravelF*1.2,0,0,ui.availableSpaceY()) ),20,rgbm(1,1,1,1))
        ac.debug('test_susTrav_FR',wheel.suspensionTravel)
        ac.debug('test_ExtraSusTrav_FR',physics.getExtendedDamperTravel(0,1))
      end)
    end
  )
  rlcam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'CAM-RL' 
    ,obs.Flags.UserSize+obs.Flags.ManualUpdate
    ,function (size)
      if shootRL then shootRL:dispose() end
      shootRL = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      shootRL:setBestSceneShotQuality()
    end, function (canvas)
      local wheel = car.wheels[2]
      local wheelPos = wheel.transform
      local camPos = wheelPos:transformPoint(vec3(cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootRL:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootRL},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
      canvas:update(function()
        if math.abs(wheel.suspensionTravel) > maxtravelR then maxtravelR = math.abs(wheel.suspensionTravel) end
        ui.drawLine(vec2(50,0),vec2(50,ui.availableSpaceY()),rgbm(0,0,0,1),7)
        ui.drawLine(vec2(100,ui.availableSpaceY()/2),vec2(0,ui.availableSpaceY()/2),rgbm(0,0,0,1),7)

        ui.drawCircleFilled(vec2(50,math.remap(wheel.suspensionTravel,maxtravelR*1.2,0,ui.availableSpaceY(),0) ),20,rgbm(1,1,1,1))
        ui.drawCircleFilled(vec2(50,math.remap(wheel.suspensionTravel,maxtravelR*1.2,0,0,ui.availableSpaceY()) ),20,rgbm(1,1,1,1))
        ac.debug('test_susTrav_RL',wheel.suspensionTravel)
        ac.debug('test_ExtraSusTrav_RL',physics.getExtendedDamperTravel(0,2))
      end)
    end
  )
  rrcam = obs.register(
    'kiyo-eng_OBSTexture'
    ,'CAM-RR' 
    ,obs.Flags.UserSize+obs.Flags.ManualUpdate
    ,function (size)
      if shootRR then shootRR:dispose() end
      shootRR = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
      shootRR:setBestSceneShotQuality()
    end, function (canvas)
      local wheel = car.wheels[3]
      local wheelPos = wheel.transform
      local camPos = wheelPos:transformPoint(vec3(-cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootRR:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootRR},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]})
      canvas:update(function()
        if math.abs(wheel.suspensionTravel) > maxtravelR then maxtravelR = math.abs(wheel.suspensionTravel) end
        ui.drawLine(vec2(ui.availableSpaceX()-50,0),vec2(ui.availableSpaceX()-50,ui.availableSpaceY()),rgbm(0,0,0,1),7)
        ui.drawLine(vec2(ui.availableSpaceX()-100,ui.availableSpaceY()/2),vec2(ui.availableSpaceX(),ui.availableSpaceY()/2),rgbm(0,0,0,1),7)

        ui.drawCircleFilled(vec2(ui.availableSpaceX()-50,math.remap(wheel.suspensionTravel,maxtravelR*1.2,0,ui.availableSpaceY(),0) ),20,rgbm(1,1,1,1))
        ui.drawCircleFilled(vec2(ui.availableSpaceX()-50,math.remap(wheel.suspensionTravel,maxtravelR*1.2,0,0,ui.availableSpaceY()) ),20,rgbm(1,1,1,1))
        ac.debug('test_susTrav_RR',wheel.suspensionTravel)
        ac.debug('test_ExtraSusTrav_RR',physics.getExtendedDamperTravel(0,3))
      end)
    end
  )
end)

function script.windowMain()
  ui.tabBar('#kiyoeng_OBSTextures',ui.TabBarFlags.None ,function()
    ui.tabItem('Chaser',function()
      ui.text('Chaser Camera Setting')
      if ui.checkbox('Activate',cameraParameters.ccamactive) then
        cameraParameters.ccamactive = not cameraParameters.ccamactive
      end
      local value,changed = ui.slider('##distance', cameraParameters.distance, 3, 10, 'DISTANCE: %.05f')
      if changed then cameraParameters.distance = value end
      local value,changed = ui.slider('##height', cameraParameters.height, 0, 5 , 'HEIGHT: %.05f')
      if changed then cameraParameters.height = value end
      local value,changed = ui.slider('##pitch', cameraParameters.pitch, -30, 30, 'PITCH: %.05f')
      if changed then cameraParameters.pitch = value end
      local value,changed = ui.slider('##fov', cameraParameters.fov, 10, 100, 'FOV: %.03f')
      if changed then cameraParameters.fov = value end
      local value,changed = ui.slider('##angleMax', cameraParameters.ccammaxangle, 0, 90, 'MAX ANGLE: %.03f')
      if changed then cameraParameters.ccammaxangle = value end
      local value,changed = ui.slider('##sensvel', cameraParameters.ccamSensiVel, 0, 1, 'SPEED SENSITIVITTY: %.03f')
      if changed then cameraParameters.ccamSensiVel = value end
    end)
    ui.tabItem('Dash',function() 
      ui.text('Dash Camera Setting')
      if ui.checkbox('Activate',cameraParameters.dashcamactive) then
        cameraParameters.dashcamactive = not cameraParameters.dashcamactive
      end
      local value,changed = ui.slider('##dashx', cameraParameters.dashx, -5, 5, 'X: %.05f')
      if changed then cameraParameters.dashx = value end
      local value,changed = ui.slider('##dashy', cameraParameters.dashy, -5, 5, 'Y: %.05f')
      if changed then cameraParameters.dashy = value end
      local value,changed = ui.slider('##dashz', cameraParameters.dashz, -5, 5, 'Z: %.05f')
      if changed then cameraParameters.dashz = value end
      local value,changed = ui.slider('##dashpitch', cameraParameters.dashpitch, -90, 90, 'PITCH: %.03f')
      if changed then cameraParameters.dashpitch = value end
      local value,changed = ui.slider('##dashroll', cameraParameters.dashroll, -90, 90, 'ROLL: %.03f')
      if changed then cameraParameters.dashroll = value end
      local value,changed = ui.slider('##dashyaw', cameraParameters.dashyaw, -90, 90, 'YAW: %.03f')
      if changed then cameraParameters.dashyaw = value end
      local value,changed = ui.slider('##dashfov', cameraParameters.fov, 10, 100, 'FOV: %.03f')
      if changed then cameraParameters.dashfov = value end
    end)
    ui.tabItem('Camber',function() 
      ui.text('Camber Camera Setting')
      if ui.checkbox('Activate',cameraParameters.cambercamactive) then
        cameraParameters.cambercamactive = not cameraParameters.cambercamactive
      end
      local value,changed = ui.slider('##offsetx', cameraParameters.camberx, -3, 3, 'X: %.05f')
      if changed then cameraParameters.camberx = value end
      local value,changed = ui.slider('##offsety', cameraParameters.cambery, -3, 3 , 'Y: %.05f')
      if changed then cameraParameters.cambery = value end
      local value,changed = ui.slider('##offsetz', cameraParameters.camberz, -3, 3, 'Z: %.05f')
      if changed then cameraParameters.camberz = value end
      local value,changed = ui.slider('##camberfov', cameraParameters.camberfov, 10, 100, 'FOV: %.03f')
      if changed then cameraParameters.camberfov = value end
    end)
  end) 
end

function script.simUpdate(dt)
  sim = ac.getSim()
  car = ac.getCar(sim.focusedCar)
  ac.forceVisibleHeadNodes(0, true) 
  if ccam and cameraParameters.ccamactive then
    smoothing.setDT(dt)
    chaseCamera(dt)
  end
  if dcam and  cameraParameters.dashcamactive then
    dashcamparam()
    dcam:update()
  end
  if flcam or frcam or rlcam or rrcam then 
    flcam:update()
    frcam:update()
    rlcam:update()
    rrcam:update()
  end
end