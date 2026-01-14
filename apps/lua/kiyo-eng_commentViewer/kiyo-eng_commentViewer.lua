local init = false
local alive = false
local settings = ac.storage{
    auto_connect = false,
    fontsize = 16
}
local jsondata ={}
local viwdata = {}
local url = 'ws://127.0.0.1:11180/sub?p=comments'
local info_url = 'http://127.0.0.1:11180/api/info'
local params = { function (err) alive = false end, function(reason) alive = false end , 'lson', true }
local error
local status

ac.setWindowBackground('main',rgbm(0,0,0,0.1) , false)

function windowMain(dt)
    ui.pushDWriteFont()

    if ui.button('reflesh') then connect() end 

    for i=0,math.min(#viwdata,9) do
        local d = viwdata[#viwdata-i]
        if d == nil then return else 
            ui.image(d[2],settings.fontsize*3,ui.ImageFit.Fill)
            ui.sameLine()
            ui.beginGroup(ui.availableSpaceX())
            ui.dwriteText(d[3]..' :',settings.fontsize)
            ui.sameLine()
            ui.offsetCursorX(ui.availableSpaceX()-((settings.fontsize*0.6)*(#d[1])/2))
            ui.offsetCursorY(settings.fontsize*0.2)
            ui.dwriteText(d[1],(settings.fontsize*0.6))
            ui.offsetCursorX(settings.fontsize*2)
            ui.dwriteTextWrapped(d[4],settings.fontsize)
            ui.endGroup()
        end
    end
end

function windowSettings(dt)
    if ui.checkbox('Auto Connect',settings.auto_connect) then 
        settings.auto_connect = not settings.auto_connect
    end
    local value,changed = ui.slider('##fontsize', settings.fontsize , 'FontSize: %.0f')
    if changed then settings.fontsize = value end


end

local meta
function prosesser(data)
    jsondata = JSON.parse(data)
    local comment = jsondata.data.comments
    if comment == {} then return else
        meta = jsondata.type
        for i=1, math.min(#comment,10) do
            local index = #comment - (i-1)
            local row={
                comment[index].data.timestamp
                ,comment[index].data.originalProfileImage
                ,comment[index].data.name
                ,comment[index].data.comment}
            viwdata[#viwdata+1] = row
        end
        for i= 1, (#viwdata-10) do
            table.remove(viwdata,i)
        end
    end
end

local sock=nil
function connect()
    viwdata ={}
    if status == 200 then
        if sock ~= nil then
            sock.close()
        end    
        sock = web.socket(url, nil, prosesser, params)
        alive = true
    end
end

function info()
    web.get(info_url,info_prossessor)
end 

function info_prossessor(err,res)
    error = err
    status = res.status
    if status == 0 then 
        alive = false
        viwdata ={}
    end
end

function update(dt)
    if init == false then
        info()
        connect()
        init = true
    end

    if (alive == false and status == 200 and settings.auto_connect) then connect() end
    
    setInterval(info, 10 ,10000)

    -- ac.debug('data',viwdata)
    -- ac.debug('alive',alive)
    -- ac.debug('jsondata',jsondata)
    -- ac.debug('meta',meta)
    -- ac.debug('err',error)
    -- ac.debug('res',status)
end