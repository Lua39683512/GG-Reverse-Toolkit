gg.showUiButton()--调用图片res/drawable/ic_ui_button_24dp.png
local DataType={D=true,F=true,E=true,Q=true,W=true,B=true,X=true}--保存HS7的输入
local format=1
local addressFormat=1
local Selected=nil
local Config={distance=8,path="/sdcard/",name="特征",file="/sdcard/特征",format=1,step4=true}--保存HS2的输入
local CompareConfig={file1="/sdcard",file2="/sdcard",name="对比结果",path="/sdcard"}--保存HS1的输入
local ListConfig={showState=false,showValues=false,maxCount=10000}--保存HS10的输入
local noComma=true
local ListTypes={{gg.TYPE_DWORD,"D"},{gg.TYPE_FLOAT,"F"},{gg.TYPE_DOUBLE,"E"},{gg.TYPE_WORD,"W"},{gg.TYPE_BYTE,"B"},{gg.TYPE_QWORD,"Q"},{gg.TYPE_XOR,"X"}}
------------------------------------------------------------------------------------------
local function FormatListValue(value)
if value==nil then return"?"end
local s=tostring(value)
local sign,integer,tail=s:match("^([+-]?)(%d+)(.*)$")
if integer and tail:match("^[%.%dEe%+%-]*$")then
integer=integer:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
s=sign..integer..tail end
return s end
local function MakeSelectedMap(items)
local selected={}
if type(items)~="table"then return selected end
for _,v in ipairs(items)do
if v.address~=nil then
if v.flags~=nil then selected[tostring(v.address)..":"..tostring(v.flags)]=true
else selected[tostring(v.address)]=true end end end
return selected end
local function IsListSelected(selected,v)
if v.flags~=nil then return selected[tostring(v.address)..":"..tostring(v.flags)]==true end
return selected[tostring(v.address)]==true end
local function GetDetailedValues(items)
local detailed={}
local batchSize=300
for first=1,#items,batchSize do
local last=math.min(first+batchSize-1,#items)
local request={}
for i=first,last do
for _,t in ipairs(ListTypes)do
request[#request+1]={address=items[i].address,flags=t[1]}end end
local values=gg.getValues(request)
if type(values)~="table"then return nil,tostring(values)end
for i=first,last do
local line={}
local base=(i-first)*#ListTypes
for j,t in ipairs(ListTypes)do
local v=values[base+j]
line[#line+1]=FormatListValue(v and v.value)..t[2]end
detailed[i]=table.concat(line,"; ")end end
return detailed end
--====================================================
function SM(title,data,isMain)--增加一个函数"SM"用于优化菜单
local menu={}
for i,v in ipairs(data)do
menu[i]=v[1]end
if not isMain then menu[#menu+1]="回到主页"end--除了末尾有"true"以外的所有菜单末尾添加回到主页这个功能
local s=gg.choice(menu,"",title)
if s then
if s<=#data then data[s][2]()else Main0()end end end--点击回到主页这个功能后回到Main0()
------------------------------------------------------------------------------------------
function TypeName(f)--增加一个函数"TypeName"
return({
[gg.TYPE_DWORD]="D",
[gg.TYPE_FLOAT]="F",
[gg.TYPE_DOUBLE]="E",
[gg.TYPE_QWORD]="Q",
[gg.TYPE_WORD]="W",
[gg.TYPE_BYTE]="B",
[gg.TYPE_XOR]="X"
})[f]or"?"end
--====================================================
    function Main0()
SM("",{
{"数值选择",Main2},
{"对比",HS1},
{"特征",Main1},
{"更新日志",HS9},
{"退出",HS0}
},true)end
    function Main2()
SM("",{
{"搜索列表",HS3},
{"保存列表",HS4},
{"地址",HS5},
{"设置",Main4}
})end
    function HS3()
local n=gg.getResultsCount()
if n==0 then gg.alert("搜索列表为空")return end
local limit=math.min(n,ListConfig.maxCount)
local selected={}
if ListConfig.showState then selected=MakeSelectedMap(gg.getSelectedResults())end
local r=gg.getResults(limit)
local ranges=gg.getValuesRange(r)
if type(ranges)~="table"then ranges={}end
local detailed
if ListConfig.showValues then
local err
detailed,err=GetDetailedValues(r)
if not detailed then gg.alert("读取详细数值失败:\n"..tostring(err))return end end
local list={}
for i,v in ipairs(r)do
local prefix=ListConfig.showState and(IsListSelected(selected,v)and"☑"or"☐")or""
local value=ListConfig.showValues and detailed[i]or FormatListValue(v.value)
local valueType=ListConfig.showValues and""or("    "..TypeName(v.flags))
list[i]=prefix..string.format("%X    %s%s    %s",v.address,value,valueType,ranges[i]or"?")end
local s=gg.choice(list,nil,"")
if not s then return end
Selected=r[s]end
    function HS4()
local selected={}
if ListConfig.showState then selected=MakeSelectedMap(gg.getSelectedListItems())end
local all=gg.getListItems()
if type(all)~="table"or #all==0 then gg.alert("保存列表为空")return end
local count=math.min(#all,ListConfig.maxCount)
local r={}
for i=1,count do r[i]=all[i]end
local ranges=gg.getValuesRange(r)
if type(ranges)~="table"then ranges={}end
local detailed
if ListConfig.showValues then
local err
detailed,err=GetDetailedValues(r)
if not detailed then gg.alert("读取详细数值失败:\n"..tostring(err))return end end
local list={}
for i,v in ipairs(r)do
local prefix=""
if ListConfig.showState then
prefix=(IsListSelected(selected,v)and"☑"or"☐")..tostring(v.freeze==true).."  "end
local namePrefix=(v.name and v.name~="")and(v.name.."    ")or""
local value=ListConfig.showValues and detailed[i]or FormatListValue(v.value)
local valueType=ListConfig.showValues and""or("    "..TypeName(v.flags))
list[i]=prefix..namePrefix..string.format("%X    %s%s    %s",v.address,value,valueType,ranges[i]or"?"
