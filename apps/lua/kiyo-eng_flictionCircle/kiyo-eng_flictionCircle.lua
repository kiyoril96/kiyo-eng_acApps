local settings = ac.storage {
  isactive = true,
  -- debug= true,
  offsetX =0,
  offsetY =0,
  scale = 2,
  thick = 3
}

local t0
local t1
local t2
local t3
local car
local uisize


function script.getState()
  car = ac.getCar(0)
  t0 = ac.getCar(0).wheels[0]
  t1 = ac.getCar(0).wheels[1]
  t2 = ac.getCar(0).wheels[2]
  t3 = ac.getCar(0).wheels[3]
end

function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2, numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

function script.scale(x,retio)
  return x*retio
end

function script.setui(wheel,offsetx,offsety)
  local offset = vec2(offsetx,offsety)
  local scale = settings.scale * 0.01
  local radius_x = script.scale(wheel.load*wheel.dy,scale)
  local radius_y = script.scale(wheel.load*wheel.dx,scale)
  local fliction_x = script.scale(-(wheel.fy),scale)
  local fliction_y = script.scale(wheel.fx,scale)
  local ndslip = wheel.ndSlip
  local color_circle = rgbm(wheel.ndSlip,1.5-wheel.ndSlip,0.5,1)
  local color_fliction = rgbm(0,1,1,1)
  local color_slip = rgbm(1,0.5,0,1)
  local segment = 40
  local thick = settings.thick
  
  --摩擦円の描画
  script.drawEllipse(offset,vec2(radius_x,radius_y),rgbm(0,0,0,0.1),segment,thick+10)
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle,segment,thick)

  --発生している摩擦力のベクトル
  ui.drawCircleFilled(offset,thick,color_fliction,segment)
  ui.drawLine(offset,vec2(offset.x+fliction_x,offset.y+fliction_y),color_fliction,thick*2)
  ui.drawCircleFilled(vec2(offset.x+fliction_x,offset.y+fliction_y),thick+2,color_fliction,segment)

  --どんだけ滑ってるか
  ui.drawCircleFilled(offset,thick,color_slip,segment)
  ui.drawLine(offset,vec2((offset.x+(fliction_x*ndslip)),(offset.y+(fliction_y*ndslip))),color_slip,thick*2)
  ui.drawCircleFilled( vec2((offset.x+(fliction_x*ndslip)),offset.y+(fliction_y*ndslip)),thick+2,color_slip,segment)
end

function script.setdebug(num,wheels)
  if settings.debug then
    ac.debug(num..'_load',wheels.load)
    ac.debug(num..'_dx',wheels.dx)
    ac.debug(num..'_dy',wheels.dy)
    ac.debug(num..'_fx',wheels.fx)
    ac.debug(num..'_fy',wheels.fy)
    ac.debug(num..'_ndSlip',wheels.ndSlip)
  end
end

function script.ty0()
  script.setui(t0,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
  --script.setdebug('t0',t0)
end

function script.ty1()
  script.setui(t1,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
  --script.setdebug('t1',t1)
end

function script.ty2()
  script.setui(t2,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
  --script.setdebug('t2',t2)
end

function script.ty3()
  script.setui(t3,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
  --script.setdebug('t3',t3)
end

function script.windowMain()
  if ui.checkbox('active',settings.isactive) then
    settings.isactive = not settings.isactive
  end
  local windowSize = uisize
  local value,changed = ui.slider('##offsetx', settings.offsetX, -(windowSize.x/4), windowSize.x/4, 'OFFSETX: %.0f')
  if changed then settings.offsetX = value end
  local value,changed = ui.slider('##offsety', settings.offsetY, -(windowSize.y/4), windowSize.y/4, 'OFFSETY: %.0f')
  if changed then settings.offsetY = value end

  local value,changed = ui.slider('##scale', settings.scale, 1, 5, 'SCALE: %.02f')
  if changed then settings.scale = value end

  local value,changed = ui.slider('##thick', settings.thick, 1, 10, 'THICKNESS: %.02f')
  if changed then settings.thick = value end

  -- if ui.checkbox('debug',settings.debug) then
  --   settings.debug = not settings.debug
  -- end
end

function script.simUpdate()
  script.getState()
  --ac.debug('acceleration',car.acceleration:length())
  uisize = ac.getUI().windowSize
  local uix = uisize.x/4
  local uiy = uisize.y/4

  if settings.isactive then
    ui.transparentWindow('Fliction_circle', vec2(0.0), uisize, function ()
      script.setui(t0,uix*1+settings.offsetX,uiy*1+settings.offsetY)
      script.setui(t1,uix*3-settings.offsetX,uiy*1+settings.offsetY)
      script.setui(t2,uix*1+settings.offsetX,uiy*3-settings.offsetY)
      script.setui(t3,uix*3-settings.offsetX,uiy*3-settings.offsetY)
    end)
  end
end