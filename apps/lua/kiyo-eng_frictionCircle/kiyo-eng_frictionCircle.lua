local obs = require('shared/utils/obs')
local t0
local t1
local t2
local t3
local car
local focus 
local uisize
local isinit = false
local uix
local uiy
local tyresConfig
local settings = ac.storage {
  isactive = true,
  gforce = false,
  slipAngle = false,
  composite = false,
  relativeTyer = false,
  guage = true,
  guageMax = 2,
  offsetX =0,
  offsetY =0,
  centerX =0,
  centerY =0,
  scale = 2,
  thick = 5
}

-- radius vec2(縦,横)
function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2.1 , numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

function script.init()
  uisize = ac.getUI().windowSize
  uix = uisize.x/4
  uiy = uisize.y/4
  tyresConfig = ac.INIConfig.carData(ac.getSim().focusedCar,'tyres.ini')
  
  -- obs init 
  local resolution_retio
  obs.notify(function ()
    obs.register('kiyo-eng_OBSTexture', 'FrictionCircle', obs.Flags.Transparent+obs.Flags.UserSize
    , function (size)
      resolution_retio = vec2(size.x/uisize.x,size.y/uisize.y)
    end
    , function (canvas,size)
      local offset = vec2(
        (settings.offsetX*resolution_retio.x),
        (settings.offsetY*resolution_retio.y))
      canvas:clear()
      canvas:update(function() 
        script.setui(car,t0,(size.x/4)*1+offset.x,(size.y/4)*1+offset.y,'FL')
        script.setui(car,t1,(size.x/4)*3-offset.x,(size.y/4)*1+offset.y,'FR')
        script.setui(car,t2,(size.x/4)*1+offset.x,(size.y/4)*3-offset.y,'RL')
        script.setui(car,t3,(size.x/4)*3-offset.x,(size.y/4)*3-offset.y,'RR')
      end)
  end)
  end
  )
  isinit = true
end

local curFocus
function script.getState()
  focus = ac.getSim().focusedCar
  if curFocus ~= focus then 
    curFocus = focus
    tyresConfig = nil
    tyresConfig = ac.INIConfig.carData(curFocus,'tyres.ini')
  end
  car = ac.getCar(curFocus)
  t0 = car.wheels[0]
  t1 = car.wheels[1]
  t2 = car.wheels[2]
  t3 = car.wheels[3]
end

function script.scale(x,retio)
  return x*retio
end

local color_circle = rgbm() 
local color_circle_alt = rgbm(0,0,0,0.1)
local color_friction = rgbm(0,1,1,1)
local color_slip = rgbm(1,0.5,0,1)
local color_gauge = rgbm(1,1,1,1)
local color_gauge_alt = rgbm(1,0,1,1)
local segment = 50
local thick = 0
local angle = 0
function script.setui(car,wheel,offsetx,offsety,tyreLabel)
  -- local tyerIndex
  -- if tyreLabel == 'FL' then tyerIndex=0
  -- elseif tyreLabel == 'FR' then tyerIndex=1
  -- elseif tyreLabel == 'RL' then tyerIndex=2
  -- elseif tyreLabel == 'RR' then tyerIndex=3
  -- end
  local offset = vec2(offsetx,offsety)
  local scaleRetio = settings.scale * 0.01
  local load = wheel.load
  local DX = wheel.dx
  local DY = wheel.dy
  local FX = wheel.fx
  local FY = wheel.fy
  local mass_1g = car.mass*2.45 -- 1/4N=9.8/4
  local setctionName = ''
  if tyreLabel == 'FL'or tyreLabel == 'FR' then setctionName = 'FRONT' else setctionName = 'REAR' end
  local dxRef = tyresConfig:get(setctionName,'DX_REF',1)*wheel.surfaceGrip
  local dyRef = tyresConfig:get(setctionName,'DY_REF',1)*wheel.surfaceGrip
  local limit_angle = tyresConfig:get(setctionName,'FRICTION_LIMIT_ANGLE',8)

  if ac.isInReplayMode() then 
    local load_remap = math.remap(load,0,mass_1g,-1,0)
    local calc_dx = ((dxRef)^(dxRef-load_remap))
    local calc_dy = ((dyRef)^(dyRef-load_remap))
    load = wheel.load
      DX = calc_dx
      DY = calc_dy
    if load > tyresConfig:get(setctionName,'FZ0',1)*9.8 then
      DX = calc_dx * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPX',1)))
      DY = calc_dy * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPY',1)))
    end
    FX = 0
    FY = 0
  end
  -- DXが縦 DYが横
  local radius_x = script.scale(load*DX,scaleRetio)
  local radius_y = script.scale(load*DY,scaleRetio)
  local friction_x = script.scale(FX,scaleRetio)
  local friction_y = script.scale(FY,scaleRetio)
  local ndslip = wheel.ndSlip
  local gaugeSize = script.scale(mass_1g*dxRef,scaleRetio)
  local gaugeMaxSize
  if settings.guage then
    gaugeMaxSize = gaugeSize*settings.guageMax
  else
    gaugeMaxSize = radius_x
  end
  thick = settings.thick
  color_circle = rgbm(wheel.ndSlip,math.clamp(2-wheel.ndSlip,0,1),0.5,1)
  local colerVal = math.abs(wheel.slipAngle)-limit_angle
  local coler_sa = rgbm((colerVal^2),((-math.clamp(colerVal,0,1)^2)+1),0,0.3)
  local coler_angle = rgbm(coler_sa.r,coler_sa.g,coler_sa.b,1)
  -- 枠
  if settings.guage then 
    ui.drawCircle(offset,gaugeSize,color_gauge,segment,thick*0.3)
    if settings.guageMax == 2 then 
      ui.drawCircle(offset,gaugeSize*2,color_gauge,segment,thick*0.3)
    elseif settings.guageMax == 3 then
      ui.drawCircle(offset,gaugeSize*2,color_gauge,segment,thick*0.3)
      ui.drawCircle(offset,gaugeSize*3,color_gauge,segment,thick*0.3)
    elseif settings.guageMax == 4 then
      ui.drawCircle(offset,gaugeSize*2,color_gauge,segment,thick*0.3)
      ui.drawCircle(offset,gaugeSize*3,color_gauge,segment,thick*0.3)
      ui.drawCircle(offset,gaugeSize*4,color_gauge,segment,thick*0.3)
    end

    
    ui.drawLine(offset-vec2(gaugeMaxSize,0),offset+vec2(gaugeMaxSize,0),color_gauge,thick*0.3)
    ui.drawLine(offset-vec2(0,gaugeMaxSize),offset+vec2(0,gaugeMaxSize),color_gauge,thick*0.3)
  end

  -- トー角(ステアリングによる角度を含む)に合わせてUIを動かすか
  if settings.relativeTyer then angle = -(wheel.toeIn) else angle = 0 end 
  ui.beginRotation()
  -- スリップアングル(エリア表示)
  if not ac.isInReplayMode() and settings.slipAngle then
    -- ここに置かないと表示が遅れる（なぜなのか）
    ui.drawPie(offset,gaugeMaxSize,math.rad(0),math.rad(wheel.slipAngle),coler_sa)
    ui.drawPie(offset,-gaugeMaxSize,math.rad(wheel.slipAngle),math.rad(0),coler_sa)
  end

  -- タイヤの向きの表示
  if settings.relativeTyer and settings.guage then
    ui.drawLine(offset-vec2(gaugeSize,0),offset+vec2(gaugeSize,0),color_gauge_alt,thick*0.3)
    ui.drawLine(offset-vec2(0,gaugeSize),offset+vec2(0,gaugeSize),color_gauge_alt,thick*0.3)
  end

  -- スリップアングル(方向表示)
  if not ac.isInReplayMode() and settings.slipAngle then
    ui.beginRotation()
      ui.drawLine(offset-vec2(0,gaugeMaxSize),offset+vec2(0,gaugeMaxSize),coler_angle,thick*0.5)
    ui.endPivotRotation((-wheel.slipAngle), offset)
  end

  --最大摩擦力（摩擦円）
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle_alt,segment,thick*2)
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle,segment,thick)

  --発生している摩擦力のベクトル
  ui.drawLine(offset,vec2(offset.x+friction_x,offset.y+friction_y),color_friction,thick*2)
  ui.drawCircleFilled(vec2(offset.x+friction_x,offset.y+friction_y),thick+2,color_friction,segment)
  --スリップ率
  ui.drawLine(offset,vec2((offset.x+(friction_x*ndslip)),(offset.y+(friction_y*ndslip))),color_slip,thick*2)
  ui.drawCircleFilled( vec2((offset.x+(friction_x*ndslip)),offset.y+(friction_y*ndslip)),thick+2,color_slip,segment)

  if not ac.isInReplayMode() then
    if settings.gforce then
      -- 車体の加速度
      local gforce = vec3():set((car.acceleration)*(load))*scaleRetio
      local rotatedFoce = gforce:rotate(quat.fromAngleAxis(-math.rad(wheel.toeIn), vec3(0,1,0)))  
      ui.drawLine(offset,vec2((offset.x+(rotatedFoce.z)),(offset.y+(-rotatedFoce.x))),rgbm(0,0,1,1),thick*1.5)
      ui.drawCircleFilled( vec2((offset.x+(rotatedFoce.z)),(offset.y+(-rotatedFoce.x))),thick+2,rgbm(0,0,1,1),segment)
      
      if settings.composite then
        -- 合成
        ui.drawLine(offset,vec2((offset.x+(rotatedFoce.z+friction_x)),(offset.y+(-rotatedFoce.x+friction_y))),color_gauge,thick*1.5)
        ui.drawCircleFilled( vec2((offset.x+(rotatedFoce.z+friction_x)),(offset.y+(-rotatedFoce.x+friction_y))),thick+2,color_gauge,segment)
      end
    end
  end
  ui.endPivotRotation(angle, offset)

  --中心点
  ui.drawCircleFilled(offset,thick,color_gauge,segment)
  
end

-- 単体ウィンドウ
-- FL
function script.ty0(dt) script.setui(car,t0,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'FL') end
-- FR
function script.ty1(dt) script.setui(car,t1,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'FR') end
-- RL
function script.ty2(dt) script.setui(car,t2,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'RL') end
-- RR
function script.ty3(dt) script.setui(car,t3,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'RR') end

function script.windowMain()
  if ui.checkbox('Active',settings.isactive) then settings.isactive = not settings.isactive end
  
  -- ゲージの表示選択
  ui.offsetCursorY(10)
  ui.text('Guage:')
  ui.indent(10)
  ui.offsetCursorY(5)
  if ui.checkbox('Show guage',settings.guage) then settings.guage = not settings.guage end
  ui.sameLine()
  ui.offsetCursorX(ui.availableSpaceX()/5)
  ui.text('Max')
  ui.sameLine()
  ui.setNextItemWidth(75)
  ui.combo('##guageMax',settings.guageMax..'G',function()
    for i=1 , 4 do 
      if ui.selectable(i..'G') then settings.guageMax = i end
    end end)
  ui.unindent(10)

  -- 基準とする方向の選択
  ui.offsetCursorY(10)
  ui.text('Reference Direction:')
  ui.indent(10)
  ui.offsetCursorY(5)
  if ui.radioButton('Wheel', settings.relativeTyer) then settings.relativeTyer = true end
  ui.sameLine()
  ui.offsetCursorX(ui.availableSpaceX()/3)
  if ui.radioButton('Car', not settings.relativeTyer) then settings.relativeTyer = false end
  ui.unindent(10)

  -- 各オフセット 都合上軸方向順に並んでる
  ui.offsetCursorY(10)
  ui.text('Width:')
  ui.sameLine()
  ui.offsetCursorX((ui.availableSpaceX()/2)-15)
  ui.text('Offset:')
  ui.indent(10)
  ui.offsetCursorY(5)
  local windowSize = uisize
  -- UIのX幅設定（これまでのOFFSETX）
  ui.setNextItemWidth((ui.availableSpaceX()/2)-15 )
  local value,changed = ui.slider('##offsetx', settings.offsetX, -(windowSize.x/4), windowSize.x/4, 'X: %.0f')
  if changed then settings.offsetX = value end
  --これで右クリックリセット
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.offsetX = 0 end 
  ui.sameLine()
  ui.offsetCursorX(15)
  -- UI全体を水平方向に動かす メインの表示にのみ適用（単体ウィンドウとOBSには反映されない）
  ui.setNextItemWidth(ui.availableSpaceX())
  local value,changed = ui.slider('##centerx', settings.centerX, -(windowSize.x/2), windowSize.x/2, 'X: %.0f')
  if changed then settings.centerX = value end
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.centerX = 0 end 
  -- UIのY幅設定（これまでのOFFSETY）
  ui.setNextItemWidth((ui.availableSpaceX()/2)-15)
  local value,changed = ui.slider('##offsety', settings.offsetY, -(windowSize.y/4), windowSize.y/4, 'Y: %.0f')
  if changed then settings.offsetY = value end
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.offsetY = 0 end 
  ui.sameLine()
  ui.offsetCursorX(15)
  -- UI全体を垂直方向に動かす メインの表示にのみ適用（単体ウィンドウとOBSには反映されない）
  ui.setNextItemWidth(ui.availableSpaceX())
  local value,changed = ui.slider('##centery', settings.centerY, -(windowSize.y/2), windowSize.y/2, 'Y: %.0f')
  if changed then settings.centerY = value end
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.centerY = 0 end 
  ui.unindent(10)
  -- サイズ
  ui.offsetCursorY(10)
  ui.text('Size:')
  ui.indent(10)
  ui.offsetCursorY(5)
  ui.setNextItemWidth((ui.availableSpaceX()/2)-15)
  local value,changed = ui.slider('##scale', settings.scale,0, 5, 'Scale: %.02f')
  if changed then settings.scale = value end
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.scale = 2 end 
  ui.sameLine()
  -- 太さ
  ui.offsetCursorX(15)
  ui.setNextItemWidth(ui.availableSpaceX())
  local value,changed = ui.slider('##thick', settings.thick, 1, 20, 'Thickness: %.02f')
  if changed then settings.thick = value end
  if ui.itemClicked(ui.MouseButton.Right, true) then  settings.thick = 5 end 

  ui.unindent(10)

  -- オプション機能
  ui.offsetCursorY(10)
  ui.text('Optional:')
  ui.indent(10)
  ui.offsetCursorY(5)
  if ui.checkbox('Gforce Vector',settings.gforce) then settings.gforce = not settings.gforce end
  ui.sameLine()
  ui.offsetCursorX(ui.availableSpaceX()/5)
  if ui.checkbox('Composite',settings.composite) then settings.composite = not settings.composite end
  ui.offsetCursorY(5)
  if ui.checkbox('Slip Angle',settings.slipAngle) then settings.slipAngle = not settings.slipAngle end
end

function script.simUpdate()
  if isinit == false then script.init() end
  script.getState()
  if settings.isactive then
    ui.transparentWindow('##friction_circle', vec2(0.0), uisize, function ()
      script.setui(car,t0,(uix*1+settings.offsetX)+settings.centerX,(uiy*1+settings.offsetY)+settings.centerY,'FL')
      script.setui(car,t1,(uix*3-settings.offsetX)+settings.centerX,(uiy*1+settings.offsetY)+settings.centerY,'FR')
      script.setui(car,t2,(uix*1+settings.offsetX)+settings.centerX,(uiy*3-settings.offsetY)+settings.centerY,'RL')
      script.setui(car,t3,(uix*3-settings.offsetX)+settings.centerX,(uiy*3-settings.offsetY)+settings.centerY,'RR')
    end)
  end
end