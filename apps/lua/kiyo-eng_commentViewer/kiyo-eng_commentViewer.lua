require('util')
local webBrowser = require('shared/web/browser')
local browser = webBrowser()
local templateList
local baseUrl = 'http://127.0.0.1:11180/'
local init =  false
local settings = ac.storage{
    selectedName =  'preset/basic',
    selectedTemplate = baseUrl..'/templates/preset/basic/',
    zoom = 1
}

local status
local alive
function info()
    web.get(baseUrl..'api/info',function(err,res) 
        error = err
        status = res.status
        if status == 0 then 
            alive = false
        else
            alive = true
        end
    end)
end 

function templates()
    web.get(baseUrl..'api/templates',function(err,res)
        if res.status == 0 then
            alive = false
            templateList = {}
        elseif res.status == 200 then
            alive = true
            templateList = JSON.parse(res.body)
        end
    end)
end 

function windowMain()
    if init and alive then
        browser:control(ui.availableSpace())
    else
        ui.dwriteDrawText('Disconnected',50,vec2(100,100))
    end
end

function windowSettings()
    ui.text('Template')
    ui.offsetCursorY(5)
    if not templateList then
        templates()
    end
    if templateList then 
        ui.combo('##templateList',settings.selectedName
            ,function()
            for i=1 , #templateList do 
                if ui.selectable(templateList[i]['dir']..'/'..templateList[i]['name']) then
                    settings.selectedTemplate = templateList[i]['url']
                    settings.selectedName = templateList[i]['dir']..'/'..templateList[i]['name']
                    browser:navigate(settings.selectedTemplate)
                end
                if ui.itemHovered() then ui.tooltip(nil,function() ui.image(templateList[i]['thumb'],vec2(200,200),ui.ImageFit.Fit) end) end
            end
        end)
    end

    ui.offsetCursorY(20)
    ui.text('Size')
    ui.offsetCursorY(5)
    local value,changed = ui.resetableSlider('##zoom', settings.zoom*100 , 0, 200, '%.0f %%',nil,100)
    if changed then 
        settings.zoom = value/100
        browser:setZoomScale(settings.zoom)   
    end

    ui.offsetCursorY(40)

    ui.text('powered by:')
    ui.offsetCursorY(10)
    ui.dwriteDrawText('配信者のためのコメントアプリ「わんコメ」',14,ui.getCursor())

    ui.offsetCursorY(20)
    ui.clickableHyperLink('https://onecomme.com')
    ui.offsetCursorY(20)
end

local interval = 3
function update() 
    if not init then
        info()
        setInterval(function() info() end ,interval,'##heartbeat')
        browser:setZoomScale(settings.zoom)
        browser:navigate(settings.selectedTemplate)
        init = true
    end
    ac.debug('alive',alive)
    ac.debug('init',init)
    ac.debug('interval',interval)
end