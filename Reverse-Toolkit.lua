gg.showUiButton()--调用图片res/drawable/ic_ui_button_24dp.png
local DataType={D=true,F=true,E=true,Q=true,W=true,B=true,X=true}--保存HS7的输入
local format=1
local Selected=nil
local Config={distance=8,path="/sdcard/",name="特征",file="/sdcard/特征",format=1,step4=true}--保存HS2的输入
local CompareConfig={file1="/sdcard",file2="/sdcard",name="对比结果",path="/sdcard"}--保存HS1的输入
local ListConfig={showState=false,showValues=false,maxCount=10000}--保存HS10的输入
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
local s=gg.choice(menu,nil,title)
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
list[i]=prefix..namePrefix..string.format("%X    %s%s    %s",v.address,value,valueType,ranges[i]or"?")end
local s=gg.choice(list,nil,"")
if not s then return end
Selected=r[s]end
    function HS5()
local a=gg.prompt({""},{},{""})
if not a then return end
local b=gg.choice({10,16},"","进制")
if not b then return end
local address
if b==1 then address=tonumber(a[1],10)else
local s=a[1]:gsub("^0[xX]","")
address=tonumber(s,16)end
if not address then gg.alert("格式错误")return end
Selected={address=address}end
    function Main4()
SM("",{
{"列表显示",HS10}
})end
     function HS10()
local a=gg.prompt(
{"显示勾选与冻结状态","数值详细显示","列表读取数量≤"},
{ListConfig.showState,ListConfig.showValues,tostring(ListConfig.maxCount)},
{"checkbox","checkbox","number"})
if not a then return end
local maxCount=tonumber(a[3])
if not maxCount or maxCount<1 or maxCount%1~=0 then gg.alert("最多显示数量必须是大于0的整数")return end
ListConfig.showState=a[1]
ListConfig.showValues=a[2]
ListConfig.maxCount=maxCount end
    function HS1()
local a=gg.prompt(
{"文件1","文件2","输出文件名","输出文件保存位置"},
{CompareConfig.file1,CompareConfig.file2,CompareConfig.name,CompareConfig.path},
{"file","file","text","path"})
if not a then return end
local file1=a[1]
local file2=a[2]
local name=a[3]
local path=a[4]
if not file1 or file1==""then gg.alert("文件1不可为空")return end
if not file2 or file2==""then gg.alert("文件2不可为空")return end
if not name or name==""then gg.alert("文件名不可为空")return end
if not path or path==""then gg.alert("保存位置不可为空")return end
CompareConfig.file1=file1
CompareConfig.file2=file2
CompareConfig.name=name
CompareConfig.path=path
if path:sub(-1)~="/"then path=path.."/"end
local f1=io.open(file1,"r")
if not f1 then gg.alert("无法打开文件1:\n"..file1)return end
local f2=io.open(file2,"r")
if not f2 then f1:close()gg.alert("无法打开文件2:\n"..file2)return end
local order={"D","F","E","W","B","Q","X"}
local validType={D=true,F=true,E=true,W=true,B=true,Q=true,X=true}
local function NormalizeOffset(s)
if not s then return nil end
s=s:match("^%s*(.-)%s*$")
local sign=1
local first=s:sub(1,1)
if first=="-"then sign=-1 s=s:sub(2)elseif first=="+"then s=s:sub(2)end
if s:match("^0[xX]")then
local n=tonumber(s:sub(3),16)
if n then return sign*n end return nil end
local n=tonumber(s)
if n then return sign*n end return nil end
local function GetValueToken(s)
local typ=s:sub(-1)
if not validType[typ]then return nil end
local value=s:sub(1,-2):gsub(",","")
local lower=value:lower()
if lower=="nan"or lower=="+nan"or lower=="-nan"or lower=="inf"or lower=="+inf"or lower=="-inf"then return value..typ,typ end
if value:match("^[+-]?%d+%.?%d*[eE][+-]?%d+$")or value:match("^[+-]?%d+%.?%d*$")or value:match("^[+-]?%d*%.%d+$")then return value..typ,typ end return nil end
local function GetLineData(line)
local rawOffset=line:match("A%[([^%]]+)%]")
local offset=NormalizeOffset(rawOffset)
local values={}
local body=line:gsub("A%[[^%]]+%]","")
body=body:match("^%s*%S+%s+(.+)$")or body
for s in body:gmatch("[^;%s]+")do
local token=GetValueToken(s)
if token then values[token]=true end end
return values,offset end
local index2={}--逐行读取文件2只保留偏移量和对应的数值索引
local count2=0
for line in f2:lines()do
count2=count2+1
local values,offset=GetLineData(line)
if offset~=nil then
local target=index2[offset]
if not target then target={}index2[offset]=target end
for token in pairs(values)do
target[token]=true end end end
f2:close()
local file=path..name--生成不重名的输出文件
local check=io.open(file,"r")
if check then
check:close()
local i=1
while true do
local newFile=path..name.."("..i..")"
local f=io.open(newFile,"r")
if f then f:close()i=i+1 else file=newFile break end end end
local out=io.open(file,"w")
if not out then f1:close()gg.alert("创建文件失败:\n"..file)return end
local count1=0--逐行读取文件1匹配成功后立即写入输出文件
local count=0
for line in f1:lines()do
count1=count1+1
local values1,offset=GetLineData(line)
local values2=offset~=nil and index2[offset]or nil
if values2 then
local types={}
for _,typ in ipairs(order)do
for token in pairs(values1)do
if token:sub(-1)==typ and values2[token]then types[#types+1]=typ break end end end
if #types>0 then out:write(line,table.concat(types,","),"\n")count=count+1 end end end
f1:close()out:close()
gg.alert("对比完成!\n".."文件1行数:"..count1.."\n".."文件2行数:"..count2.."\n保留:"..count.."行\n".."文件:"..file)end
    function Main1()
SM("",{
{"扫描",HS8},
{"设置",Main3}
})end
    function HS8()
if not Selected then gg.alert("数值未选择")return end
local types={}
if DataType.D then types[#types+1]={gg.TYPE_DWORD,"D"}end
if DataType.F then types[#types+1]={gg.TYPE_FLOAT,"F"}end
if DataType.E then types[#types+1]={gg.TYPE_DOUBLE,"E"}end
if DataType.W then types[#types+1]={gg.TYPE_WORD,"W"}end
if DataType.B then types[#types+1]={gg.TYPE_BYTE,"B"}end
if DataType.Q then types[#types+1]={gg.TYPE_QWORD,"Q"}end
if DataType.X then types[#types+1]={gg.TYPE_XOR,"X"}end
local address=Selected.address
local distance=Config.distance
local request={}
local offsetList={}
local step=Config.step4 and 4 or 1
local maxOffset=Config.step4 and math.floor(distance/4)*4 or distance
for offset=-maxOffset,maxOffset,step do
local base=#request
for _,v in ipairs(types)do
request[#request+1]={address=address+offset,flags=v[1]}end
offsetList[#offsetList+1]={offset=offset,base=base}end
local result=gg.getValues(request)
if type(result)~="table"then gg.alert("读取失败")return end
local function FormatValue(v)
local s=tostring(v)
s=s:gsub("^nan$","NaN")
s=s:gsub("^-nan$","-NaN")
s=s:gsub("^inf$","Inf")
s=s:gsub("^-inf$","-Inf")
local a,b,c=s:match("^([%-]?)(%d+)(%.%d+)$")
if a then b=b:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")s=a..b..c else
local x,y=s:match("^([%-]?)(%d+)$")
if x then y=y:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")s=x..y end end return s end
local file=Config.path..Config.name
local i=1
while true do
local check=io.open(file,"rb")
if check then check:close()file=Config.path..Config.name.."("..i..")"i=i+1 else break end end
Config.file=file
local f=io.open(file,"w")
if not f then gg.alert("创建文件失败:\n"..file)return end
local count=0
for _,o in ipairs(offsetList)do
local line={}
local pos=o.base
for i,v in ipairs(types)do
local r=result[pos+i]
if r and r.address==address+o.offset then line[#line+1]=FormatValue(r.value)..v[2]end end
if #line>0 then
local offset
if format==1 then offset=string.format("%.0f",o.offset)else
if o.offset<0 then offset="-0x"..string.format("%X",-o.offset)else offset="0x"..string.format("%X",o.offset)end end
f:write(string.format("%X",address+o.offset),"    ",table.concat(line,"  ;  "),"    A[",offset,"]\n")
count=count+1 end end
f:close()
gg.alert("扫描完成!\n".."地址:"..string.format("%X",address).."\n".."扫描范围:±"..distance.."\n".."生成:"..count.."行\n".."文件:"..Config.file)end
    function Main3()
SM("",{
{"数据类型",HS7},
{"偏移量进制",HS6},
{"其它",HS2}
})end
    function HS7()
local a=gg.prompt(
{"D","F","E","W","B","Q","X"},
{DataType.D,DataType.F,DataType.E,DataType.W,DataType.B,DataType.Q,DataType.X},
{"checkbox","checkbox","checkbox","checkbox","checkbox","checkbox","checkbox"})
if not a then return end
if not(a[1]or a[2]or a[3]or a[4]or a[5]or a[6]or a[7])then gg.alert("至少选择其一")return end
DataType.D=a[1]
DataType.F=a[2]
DataType.E=a[3]
DataType.W=a[4]
DataType.B=a[5]
DataType.Q=a[6]
DataType.X=a[7]end
    function HS6()
local f=gg.choice({10,16},format,"")
if not f then return end
format=f end
    function HS2()
local function FeatureConfig()
local a=gg.prompt(
{"特征距离≤","特征文件保存位置","特征文件名称","地址间隔4"},
{Config.distance,Config.path,Config.name,Config.step4},
{"","path","text","checkbox"})
if not a then return end
local distance=tonumber(a[1])
local path=a[2]
local name=a[3]
local step4=a[4]
if not distance or distance<0 or distance%1~=0 then gg.alert("特征距离必须是不小于0的整数")return end
if not path or path==""then gg.alert("保存位置不可为空")return end
if not name or name==""then gg.alert("文件名不可为空")return end
if path:sub(-1)~="/"then path=path.."/"end
return{distance=distance,path=path,name=name,file=path..name,format=format,step4=step4}end
local c=FeatureConfig()
if c then Config=c gg.alert("设置成功!\n"..c.file.."\n特征距离:≤"..c.distance.."\n偏移量进制:"..(c.format==1 and"10"or"16").."\n地址间隔:"..(c.step4 and"4"or"1"))end end
    function HS9()
gg.alert(gg.makeRequest("https://raw.githubusercontent.com/Lua39683512/GG-Reverse-Toolkit/main/Changelog.md").content,"v1.1.1")end
--====================================================
while true do--循环
if gg.isClickedUiButton()then Main0()end gg.sleep(100)end--检测res/drawable/ic_ui_button_24dp.png是否被点击,若被点击则打开Main0(),每次检测间隔100ms
