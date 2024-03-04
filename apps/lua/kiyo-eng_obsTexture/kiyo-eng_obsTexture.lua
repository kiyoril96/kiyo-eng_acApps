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
          ret = 2 * ret / (1+ret);
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
          ret = 2 * ret / (1+ret);
        return float4(ret.rgb,1);
      }]]
    })
  end
)


local car 
local simstate
function camera(dt)

  local pos
  local dir
  local up 
  local fov = 60
  local carVelocity = smoothing(vec3(), 40)
  local lastCarPos = vec3()
  local lookDirection = smoothing(0, 10)
  local cameraParameters = {
    height = 2.3
    , pitch = 7
    , distance = 4 
  }
  local distance = cameraParameters.distance + 1.6
  local height = cameraParameters.height - 0.3
  local pitchAngle = cameraParameters.pitch - 5

  local carPos = car.position
  local tmpcarDir = vec3(car.velocity.x,car.velocity.y,car.velocity.z)
  local carDir = tmpcarDir:normalize()
  local carUp = car.up
  local carRight = math.cross(carDir, carUp):normalize()

  --local t1,t2,t3,t4 = car.wheels[0],car.wheels[1],car.wheels[2],car.wheels[3]
  --local centpos = (t1.position+ t2.position+ t3.position+ t4.position)/4 
  --local carPos = centpos --car.position
  --local whlooks = ((t1.look+ t2.look+ t3.look+ t4.look )/4):normalize()
  --local carDir = car.look
  --local carUp = car.up
  --local carRight = math.cross(carDir, carUp):normalize()
  --local distance = 4
  --local height =1
  --local pitchAngle = -22

  --if calculateVelocityHere then
    -- Altenative approach, using coordinates and time delta
  if lastCarPos ~= carPos then
    if lastCarPos ~= vec3() then
      local delta = lastCarPos - carPos
      local deltaLength = #delta
      if deltaLength > 5 then delta = delta / deltaLength * 5 end
      carVelocity:update(-delta / dt)
    end
    lastCarPos = carPos
  end
  --else
  --  -- Update smoothing thing with velocity:
  --  -- Note: method `updateIfNew` would change value only if parameter is different from the one used last 
  --  -- time. This way, in replays camera will freeze.
  --  carVelocity:updateIfNew(ac.getCarVelocity())
  --end

  local carVelocityDir = math.normalize(carVelocity.val + carDir * 0.01)
  local velocityX = math.clamp(math.dot(carRight, carVelocityDir) * math.pow(#carVelocity.val, 0.5) / 10, -1, 1)
  local cameraAngle = -velocityX * math.radians(54)
  --lookDirection:update(math.sign(lookDirection.val))
  cameraAngle = cameraAngle + lookDirection.val * math.pi
  local sinAngle = math.sin(cameraAngle)
  local cosAngle = math.cos(cameraAngle)

  pos = (vec3(carPos.x ,carPos.y ,carPos.z )) + (carRight * sinAngle - carDir * cosAngle) * distance + vec3(0,height,0)
  
  local cameraLookPosOffset = carDir + carUp * (1-math.abs(lookDirection.val))
  local cameraLook = (carPos + cameraLookPosOffset - pos ):normalize()

  cameraLook:rotate(quat.fromAngleAxis(math.radians(pitchAngle), carRight))
  dir = cameraLook
  up = (carUp + vec3(0,3,0)):normalize()

  return {pos = pos , direction = dir , up = up  , fov = fov }
end


function script.simUpdate(dt)
  smoothing.setDT(dt)
  ac.forceVisibleHeadNodes(0, true)
  scam:update()
  car= ac.getCar()
  simstate = ac.getSim()
  local params = camera(dt)
  pos = params.pos 
  dir = params.direction
  up = params.up
  fov = params.fov
  ccam:update()
end