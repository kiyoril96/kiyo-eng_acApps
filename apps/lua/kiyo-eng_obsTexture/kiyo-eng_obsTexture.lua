-- Access OBS helper library:
local obs = require('shared/utils/obs')
local sim
local vr
local car 
local cameraParameters = ac.storage{
  isactive =true
  , ccamactive = true
  , dashcamactive =true
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

local cshot
local pos
local dir
local up 
local fov
local ccam
obs.notify( function()
ccam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'ChaserCamera' 
  ,obs.Flags.UserSize+obs.Flags.ManualUpdate
  ,function (size)
    if cshot then cshot:dispose() end
    cshot = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.YEBIS, render.TextureFormat.R11G11B10.Float)
    cshot:setBestSceneShotQuality()
  end, function (canvas)
    cshot:update(pos,dir,up,fov)
    canvas:updateWithShader({
      textures = { tx1 = cshot},
      shader = [[
      float4 main(PS_IN pin){
        float4 ret = tx1.Sample(samLinear,pin.Tex);
      return float4(ret.rgb,1);
    }]]
    })
  end
)
end)

local dashcam
local dpos
local ddir
local dup
local dfov
local dcam
obs.notify( function()
dcam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'DashbordCamera' 
  ,obs.Flags.UserSize
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
    }]]
    })
  end
)
end)

local shootFL
local shootFR
local shootRL
local shootRR
local wheelPos
-- local carPos
local flcam
local frcam
local rlcam
local rrcam

local node = ac.findNodes('sceneRoot:yes')

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
      local wheel = ac.getCar(0).wheels[0]
      wheelPos = wheel.transform
      -- carPos = ac.getCar(0).transform
      local camPos = wheelPos:transformPoint(vec3(cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootFL:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootFL},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]
      })
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
      local wheel = ac.getCar(0).wheels[1]
      wheelPos = wheel.transform
      -- carPos = ac.getCar(0).transform
      local camPos = wheelPos:transformPoint(vec3(-cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootFR:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootFR},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]
      })
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
      local wheel = ac.getCar(0).wheels[2]
      wheelPos = wheel.transform
      -- carPos = ac.getCar(0).transform
      local camPos = wheelPos:transformPoint(vec3(cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootRL:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootRL},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]
      })
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
      local wheel = ac.getCar(0).wheels[3]
      wheelPos = wheel.transform
      -- carPos = ac.getCar(0).transform
      local camPos = wheelPos:transformPoint(vec3(-cameraParameters.camberx,cameraParameters.cambery,cameraParameters.camberz))
      shootRR:update(camPos,wheelPos.look,wheel.contactNormal,cameraParameters.camberfov)
      canvas:updateWithShader({
        textures = { tx1 = shootRR},
        shader = [[
        float4 main(PS_IN pin){
          float4 ret = tx1.Sample(samLinear,pin.Tex);
        return float4(ret.rgb,1);
      }]]
      })
    end
  )
end)

local carVelocity = smoothing(vec3(), 40)
local lastCarPos = vec3()
local lookDirection = smoothing(0, 40)
function chaseCamera(dt)
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
  local velocityX = math.clamp((math.dot(carTf.side, carVelocityDir) * ((#carVelocity.val)^cameraParameters.ccamSensiVel)) /10, -1, 1)
  local cameraAngle = velocityX * math.radians(cameraParameters.ccammaxangle)
  cameraAngle = cameraAngle + lookDirection.val * math.pi
  local sinAngle = math.sin(cameraAngle)
  local cosAngle = math.cos(cameraAngle)
  pos = carTf:transformPoint(vec3(sinAngle*cameraParameters.distance,cameraParameters.height,-cosAngle*cameraParameters.distance))
  local cameraLookPosOffset = carTf.look + carTf.up * (1-math.abs(lookDirection.val))
  local cameraLook = (carTf.position + cameraLookPosOffset - pos ):normalize()
  cameraLook:rotate(quat.fromAngleAxis(math.radians(cameraParameters.pitch), carTf.side))
  up = (carTf.up + vec3(0,2,0)):normalize()
  return {pos = pos , direction = cameraLook , up = up  , fov = cameraParameters.fov }
end

function script.windowMain()
  if ui.checkbox('Activate',cameraParameters.isactive) then
    cameraParameters.isactive = not cameraParameters.isactive
  end 

  if cameraParameters.isactive then
    if ui.checkbox('Chase Cam Activate',cameraParameters.ccamactive) then
      cameraParameters.ccamactive = not cameraParameters.ccamactive
    end

    ui.text('Chaser Camera Setting')
    local value,changed = ui.slider('##distance', cameraParameters.distance, 3, 10, 'DISTANCE: %.02f')
    if changed then cameraParameters.distance = value end
    local value,changed = ui.slider('##height', cameraParameters.height, 0, 5 , 'HEIGHT: %.02f')
    if changed then cameraParameters.height = value end
    local value,changed = ui.slider('##pitch', cameraParameters.pitch, -10, 10, 'PITCH: %.02f')
    if changed then cameraParameters.pitch = value end
    local value,changed = ui.slider('##fov', cameraParameters.fov, 10, 100, 'FOV: %.02f')
    if changed then cameraParameters.fov = value end
    local value,changed = ui.slider('##angleMax', cameraParameters.ccammaxangle, 0, 90, 'MAX ANGLE: %.02f')
    if changed then cameraParameters.ccammaxangle = value end
    local value,changed = ui.slider('##sensvel', cameraParameters.ccamSensiVel, 0, 1, 'SPEED SENSITIVITTY: %.03f')
    if changed then cameraParameters.ccamSensiVel = value end
    
    ui.text('Dash Camera Setting')
    local value,changed = ui.slider('##dashx', cameraParameters.dashx, -5, 5, 'X: %.02f')
    if changed then cameraParameters.dashx = value end
    local value,changed = ui.slider('##dashy', cameraParameters.dashy, -5, 5, 'Y: %.02f')
    if changed then cameraParameters.dashy = value end
    local value,changed = ui.slider('##dashz', cameraParameters.dashz, -5, 5, 'Z: %.02f')
    if changed then cameraParameters.dashz = value end
    
    local value,changed = ui.slider('##dashpitch', cameraParameters.dashpitch, -90, 90, 'PITCH: %.02f')
    if changed then cameraParameters.dashpitch = value end
    local value,changed = ui.slider('##dashroll', cameraParameters.dashroll, -90, 90, 'ROLL: %.02f')
    if changed then cameraParameters.dashroll = value end
    local value,changed = ui.slider('##dashyaw', cameraParameters.dashyaw, -90, 90, 'YAW: %.02f')
    if changed then cameraParameters.dashyaw = value end
    local value,changed = ui.slider('##dashfov', cameraParameters.fov, 10, 100, 'FOV: %.02f')
    if changed then cameraParameters.dashfov = value end
    
    ui.text('Camber Camera Setting')
    local value,changed = ui.slider('##offsetx', cameraParameters.camberx, -3, 3, 'X: %.03f')
    if changed then cameraParameters.camberx = value end
    local value,changed = ui.slider('##offsety', cameraParameters.cambery, -3, 3 , 'Y: %.03f')
    if changed then cameraParameters.cambery = value end
    local value,changed = ui.slider('##offsetz', cameraParameters.camberz, -3, 3, 'Z: %.03f')
    if changed then cameraParameters.camberz = value end
    local value,changed = ui.slider('##camberfov', cameraParameters.camberfov, 10, 100, 'FOV: %.02f')
    if changed then cameraParameters.camberfov = value end
  end
end

-- local updatelate
local deltaTime = 0
function script.simUpdate(dt)
  deltaTime = deltaTime+dt

  if cameraParameters.ccamactive then
      sim = ac.getSim()
      car = ac.getCar(sim.focusedCar)
      ac.forceVisibleHeadNodes(0, true) 
      smoothing.setDT(deltaTime)

      local params = chaseCamera(deltaTime)
      pos = params.pos 
      dir = params.direction
      up = params.up
      fov = params.fov
      ccam:update()
    end

    local carlook = ac.getCar().look
    local carside = ac.getCar().side
    local temp = nil
    dpos = car.transform:transformPoint(vec3(cameraParameters.dashx,cameraParameters.dashy,cameraParameters.dashz))
    ddir = vec3(carlook.x,math.sin(cameraParameters.dashpitch/180*math.pi),carlook.z )
    if carlook.x > 0 then
      temp = math.acos(ddir.z) - cameraParameters.dashyaw/180*math.pi
      ddir.x = math.sin(temp)
      ddir.z = math.cos(temp)        
    else
      temp = -math.acos(ddir.z) - cameraParameters.dashyaw/180*math.pi
      ddir.x = math.sin(temp)
      ddir.z = math.cos(temp)        
    end
    dup = car.up
    --vec3((carside.x * math.sin(cameraParameters.dashroll/180*math.pi)),(math.cos(cameraParameters.dashroll/180*math.pi)),(carside.z * math.sin(cameraParameters.dashroll/180*math.pi)))
    dfov = cameraParameters.dashfov
    deltaTime = 0

  if flcam or frcam or rlcam or rrcam then 
    flcam:update()
    frcam:update()
    rlcam:update()
    rrcam:update()
  end
end