-- Access OBS helper library:
local obs = require('shared/utils/obs')

local sshot1
local sshot2
local scam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'SpectatorView'
  ,obs.Flags.ManualUpdate + obs.Flags.ApplyCMAA + obs.Flags.UserSize
  ,function(size)
    if sshot1 then sshot1:dispose() end
    if sshot2 then sshot2:dispose() end
    local node = ac.findNodes('sceneRoot:yes')
    sshot1 = ac.GeometryShot(node, size,  1, true, 104, 26,0)
    sshot2 = ac.GeometryShot(node, size,  1, true, 104, 26,0)
    sshot1:setClippingPlanes(0.5, 5e3)
    sshot2:setClippingPlanes(0.5, 5e3)
    sshot1:setBestSceneShotQuality()
    sshot2:setBestSceneShotQuality()
    sshot2:setShadersType(render.ShadersType.SimplifiedWithLights)
  end ,function (canvas)
    sshot1:updateWithTrackCamera(0)
    sshot2:updateWithTrackCamera(0)
    canvas:updateWithShader({
      textures = { tx1 = sshot1 ,tx2 = sshot2},
      shader = [[
        float4 main(PS_IN pin){
          float4 r1 = tx1.Sample(samLinear,pin.Tex);
          float4 r2 = tx2.Sample(samLinear,pin.Tex);
          float4 ret = (r1*0.7) + (r2*0.5);
          ret = 1.8 * ret / (1+ret);
        return float4(ret.rgb,1);
      }]]
    })
  end
)

local cshot
local cshot2
local pos
local dir
local up 
local fov
local ccam = obs.register(
  'kiyo-eng_OBSTexture'
  ,'ChaserCamera' 
  ,obs.Flags.ManualUpdate + obs.Flags.ApplyCMAA + obs.Flags.UserSize
  ,function (size)
    if cshot then cshot:dispose() end
    if cshot2 then cshot2:dispose() end
    local node = ac.findNodes('sceneRoot:yes')
    cshot = ac.GeometryShot(node, size, 1, true, 104, 26,0)
    cshot2 = ac.GeometryShot(node, size, 1, true, 104, 26,0)
    cshot:setClippingPlanes(0.5, 5e3)
    cshot2:setClippingPlanes(0.5, 5e3)
    cshot:setBestSceneShotQuality()
    cshot2:setBestSceneShotQuality()
    cshot2:setShadersType(render.ShadersType.SimplifiedWithLights)
  end, function (canvas)
    cshot:update(pos,dir,up,fov)
    cshot2:update(pos,dir,up,fov)
    canvas:updateWithShader({
      textures = { tx1 = cshot,tx2 =cshot2},
      shader = [[
        float4 main(PS_IN pin){
          float4 r1 = tx1.Sample(samLinear,pin.Tex);
          float4 r2 = tx2.Sample(samLinear,pin.Tex);
          float4 ret = (r1*0.7) + (r2*0.5);
          ret = 1.8 * ret / (1+ret);
        return float4(ret.rgb,1);
      }]]
    })
  end
)

local carVelocity = smoothing(vec3(), 40)
local lastCarPos = vec3()
local lookDirection = smoothing(0, 10)

local cameraParameters = ac.storage{
  height = 1.7
  , pitch = 0
  , distance = 5 
  , fov =60
}

local car 
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
  local value,changed = ui.slider('##distance', cameraParameters.distance, 3, 10, 'DISTANCE: %.02f')
  if changed then cameraParameters.distance = value end
  local value,changed = ui.slider('##height', cameraParameters.height, 0, 5 , 'HEIGHT: %.02f')
  if changed then cameraParameters.height = value end
  local value,changed = ui.slider('##pitch', cameraParameters.pitch, -10, 10, 'PITCH: %.02f')
  if changed then cameraParameters.pitch = value end
  local value,changed = ui.slider('##fov', cameraParameters.fov, 10, 100, 'FOV: %.02f')
  if changed then cameraParameters.fov = value end
end

function script.simUpdate(dt)
  smoothing.setDT(dt)
  ac.forceVisibleHeadNodes(0, true)
  scam:update()
  car= ac.getCar()
  local params = camera(dt)
  pos = params.pos 
  dir = params.direction
  up = params.up
  fov = params.fov
  ccam:update()
end