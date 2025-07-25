-- Access OBS helper library:
local obs = require('shared/utils/obs')
local sim
local vr
local car 
local cameraParameters = ac.storage{
  isactive =true
  , ccamactive = true
  , scamactive = true
  , fcamactive = true
  , dashcamactive =true
  , vrlook = true
  , fheight = 0
  , height = 1.7
  , pitch = 0
  , distance = 5 
  , fov =60
  , fps = 30
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
}

local node = ac.findNodes('sceneRoot:yes')

--local sshot
--local scam = obs.register(
--  'kiyo-eng_OBSTexture'
--  ,'SpectatorView'
--  ,obs.Flags.UserSize
--  ,function(size)
--    if sshot then sshot:dispose() end
--    sshot = ac.GeometryShot(node, size,  1, true, render.AntialiasingMode.YEBIS, render.TextureFormat.R16G16B16A16.Float)
--    sshot:setClippingPlanes(0.01, 5e3)
--    sshot:setBestSceneShotQuality()
--  end ,function (canvas)
--    sshot:updateWithTrackCamera(0)
--    canvas:updateWithShader({
--      textures = { tx1 = sshot},
--      shader = [[
--      float4 main(PS_IN pin){
--        float4 ret = tx1.Sample(samLinear,pin.Tex);
--      return float4(ret.rgb,1);
--    }]]
--    })
--  end
--)

local cshot
local pos
local dir
local up 
local fov
local ccam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'ChaserCamera' 
  ,obs.Flags.UserSize
  ,function (size)
    if cshot then cshot:dispose() end
    cshot = ac.GeometryShot(node, size, 1, true, render.AntialiasingMode.YEBIS, render.TextureFormat.R16G16B16A16.Float)
    cshot:setClippingPlanes(0.01, 5e3)
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

local firstshot
local fpos
local fdir
local fup 
local ffov
local fcam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'FirstPersonCamera' 
  ,obs.Flags.UserSize
  ,function (size)
    if firstshot then firstshot:dispose() end
    firstshot = ac.GeometryShot(node, size, 1, true, render.AntialiasingMode.YEBIS, render.TextureFormat.R16G16B16A16.Float)
    firstshot:setClippingPlanes(0.01, 5e3)
    firstshot:setBestSceneShotQuality()
    end, function (canvas)
    firstshot:update(fpos,fdir,fup,ffov)
    canvas:updateWithShader({
      textures = { tx1 = firstshot},
      shader = [[
      float4 main(PS_IN pin){
        float4 ret = tx1.Sample(samLinear,pin.Tex);
      return float4(ret.rgb,1);
    }]]
    })
  end
)

local dashcam
local dpos
local ddir
local dup
local dfov
local dcam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'DashbordCamera' 
  ,obs.Flags.UserSize
  ,function (size)
    if dashcam then dashcam:dispose() end
    dashcam = ac.GeometryShot(node, size, 1, true, render.AntialiasingMode.YEBIS, render.TextureFormat.R16G16B16A16.Float)
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

local carVelocity = smoothing(vec3(), 40)
local lastCarPos = vec3()
local lookDirection = smoothing(0, 10)
function camera(dt)

  local pos
  local dir
  local up 

  local distance = cameraParameters.distance
  local height = cameraParameters.height
  local pitchAngle = cameraParameters.pitch

  local carPos = (car.wheels[0].contactPoint + car.wheels[1].contactPoint+car.wheels[2].contactPoint + car.wheels[3].contactPoint)/4
  local carDir = car.look
  local carUp = car.up
  local carRight = math.cross(carDir, carUp):normalize()

  if lastCarPos ~= carPos then
    if lastCarPos ~= vec3() then
      local delta = lastCarPos - carPos
      local deltaLength = #delta
      if deltaLength > 5 then delta = delta / deltaLength * 5 end
      carVelocity:update(-delta / dt)
    end
    lastCarPos = carPos
  end

  local carVelocityDir = math.normalize(carVelocity.val + carDir * 0.01)
  local velocityX = math.clamp(math.dot(carRight, carVelocityDir) * math.pow(#carVelocity.val, 0.5) / 10, -1, 1)
  local cameraAngle = -velocityX * math.radians(54)
  cameraAngle = cameraAngle + lookDirection.val * math.pi
  local sinAngle = math.sin(cameraAngle)
  local cosAngle = math.cos(cameraAngle)
  pos = (vec3(carPos.x ,carPos.y ,carPos.z )) + (carRight * sinAngle - carDir * cosAngle) * distance + vec3(0,height,0)
  local cameraLookPosOffset = carDir + carUp * (1-math.abs(lookDirection.val))
  local cameraLook = (carPos + cameraLookPosOffset - pos ):normalize()
  cameraLook:rotate(quat.fromAngleAxis(math.radians(pitchAngle), carRight))
  dir = cameraLook
  up = (carUp + vec3(0,3,0)):normalize()
  return {pos = pos , direction = dir , up = up  , fov = cameraParameters.fov }
end

function script.windowMain()
  if ui.checkbox('Activate',cameraParameters.isactive) then
    cameraParameters.isactive = not cameraParameters.isactive
  end 

  if cameraParameters.isactive then
    -- ui.text('UPDATE RATE')
    -- local value,changed = ui.slider('##UPDATERATE', cameraParameters.fps, 24, 120, 'FPS: %.0f')
    -- if changed then cameraParameters.fps = value end

    if ui.checkbox('Chase Cam Activate',cameraParameters.ccamactive) then
      cameraParameters.ccamactive = not cameraParameters.ccamactive
    end

    -- if ui.checkbox('Spectator Cam Activate',cameraParameters.scamactive) then
    --   cameraParameters.scamactive = not cameraParameters.scamactive
    -- end

    if ui.checkbox('First Cam Activate',cameraParameters.fcamactive) then
      cameraParameters.fcamactive = not cameraParameters.fcamactive
    end

    if ui.checkbox('VR look',cameraParameters.vrlook) then
      cameraParameters.vrlook = not cameraParameters.vrlook
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

    ui.text('First Person Camera Setting')
    local value,changed = ui.slider('##fheight', cameraParameters.fheight, -1, 1 , 'FIRST_HEIGHT: %.02f')
    if changed then cameraParameters.fheight = value end

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
  end
end

-- local updatelate
local deltaTime = 0
function script.simUpdate(dt)
  deltaTime = deltaTime+dt
  --updatelate = 1 / cameraParameters.fps
  --if deltaTime >= (updatelate) and cameraParameters.isactive then 
    
    if cameraParameters.scamactive or cameraParameters.ccamactive or cameraParameters.fcamactive then
      sim = ac.getSim()
      vr = ac.getVR()
      car = ac.getCar(sim.focusedCar)
      ac.forceVisibleHeadNodes(0, true) 
      smoothing.setDT(deltaTime)
    end

    -- if cameraParameters.scamactive then
    --   scam:update()
    -- end

    if cameraParameters.ccamactive then
      local params = camera(deltaTime)
      pos = params.pos 
      dir = params.direction
      up = params.up
      fov = params.fov
      --ccam:update()
    end

    if cameraParameters.fcamactive then
      if sim.isVRMode and cameraParameters.vrlook then 
        fpos = vec3(vr.headTransform.position.x,vr.headTransform.position.y + cameraParameters.fheight ,vr.headTransform.position.z)
        fdir = -vr.headTransform.look
        fup = vr.headTransform.up
        ffov = 60
      else
        fpos = sim.cameraPosition + (sim.cameraLook* 0.05)
        fdir = sim.cameraLook
        fup =  sim.cameraUp
        ffov = sim.cameraFOV
      end
    end

    local carpos = ac.getCar().position
    local carlook = ac.getCar().look
    local carside = ac.getCar().side
    local temp = nil
    --local carangle = ac.getCar().localVelocity

    dpos = vec3((carpos.x - cameraParameters.dashz * carlook.x - cameraParameters.dashx * carlook.z),(carpos.y + cameraParameters.dashy),(carpos.z - cameraParameters.dashz * carlook.z + cameraParameters.dashx * carlook.x))
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
    dup = vec3((carside.x * math.sin(cameraParameters.dashroll/180*math.pi)),(math.cos(cameraParameters.dashroll/180*math.pi)),(carside.z * math.sin(cameraParameters.dashroll/180*math.pi)))
    dfov = cameraParameters.dashfov
    --fcam:update()
    --dcam:update()

    --ac.debug('angle' , vec3(carangle.x/math.pi,carangle.y/math.pi,carangle.z/math.pi))
    deltaTime = 0
  --end 
end