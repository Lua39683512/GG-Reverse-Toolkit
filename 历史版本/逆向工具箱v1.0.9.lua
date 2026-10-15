gg.showUiButton()--调用图片res/drawable/ic_ui_button_24dp.png
local DataType={D=true,F=true,E=true,Q=true,W=true,B=true,X=true}--保存HS7的输入
local format=1
local Selected=nil
local Config={distance=8,path="/sdcard/",name="特征",file="/sdcard/特征",format=1,step4=true}--保存HS2的输入
local CompareConfig={file1="/sdcard",file2="/sdcard",name="对比结果",path="/sdcard"}--保存HS1的输入
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
{"地址",HS5}
})end
    function HS3()
local n=gg.getResultsCount()
if n==0 then gg.alert("搜索列表为空")return end
local r=gg.getResults(n)
local list={}
for i,v in ipairs(r)do
local m=gg.getValuesRange({v.address})
list[i]=string.format("%X    %s    %s    %s",v.address,tostring(v.value),TypeName(v.flags),m[1]or"?")end
local s=gg.choice(list,nil,"")
if not s then return end
Selected=r[s]end
    function HS4()
local r=gg.getListItems()
if #r==0 then gg.alert("保存列表为空")return end
local list={}
for i,v in ipairs(r)do
local m=gg.getValuesRange({v.address})
list[i]=string.format("%s    %X    %s    %s    %s",v.name or"",v.address,tostring(v.value),TypeName(v.flags),m[1]or"?")end
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
local list1={}
local list2={}
for line in f1:lines()do list1[#list1+1]=line end
for line in f2:lines()do list2[#list2+1]=line end
f1:close()f2:close()
local order={"D","F","E","W","B","Q","X"}
local validType={D=true,F=true,E=true,W=true,B=true,Q=true,X=true}
local function NormalizeOffset(s)
if not s then return nil end
s=s:match("^%s*(.-)%s*$")
local sign=1
local first=s:sub(1,1)
if first=="-"then sign=-1 s=s:sub(2)
elseif first=="+"then s=s:sub(2)end
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
local body=line:gsub("A%[[^%]]+%]","")--忽略每行开头的地址,只解析数值字段,避免地址末尾的D/F等被误认为数值类型
body=body:match("^%s*%S+%s+(.+)$")or body
for s in body:gmatch("[^;%s]+")do
local token=GetValueToken(s)
if token then values[token]=true end end return values,offset end
local index2={}
for _,line in ipairs(list2)do--先为文件2建立“偏移量->数值及类型集合”的索引,不依赖行号和排列顺序
local values,offset=GetLineData(line)
if offset~=nil then
local target=index2[offset]
if not target then target={}index2[offset]=target end
for token in pairs(values)do target[token]=true end end end
local result={}
local count=0
for _,line in ipairs(list1)do
local values1,offset=GetLineData(line)
local values2=offset~=nil and index2[offset]or nil
if values2 then
local types={}
for _,typ in ipairs(order)do
for token in pairs(values1)do
if token:sub(-1)==typ and values2[token]then types[#types+1]=typ break end end end
if #types>0 then
result[#result+1]=line..table.concat(types,",")
count=count+1 end end end
local file=path..name
local check=io.open(file,"r")
if check then
check:close()
local i=1
while true do
local newName=name.."("..i..")"
local newFile=path..newName
local f=io.open(newFile,"r")
if f then f:close()i=i+1 else file=newFile break end end end
local out=io.open(file,"w")
if not out then gg.alert("创建文件失败:\n"..file)return end
for _,line in ipairs(result)do out:write(line,"\n")end
out:close()
gg.alert("对比完成!\n".."文件1行数:"..#list1.."\n".."文件2行数:"..#list2.."\n".."保留:"..count.."行\n".."文件:"..file)end
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
for offset=-distance,distance,step do
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
if format==1 then offset=tostring(o.offset)else
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
if not distance or distance<0 then gg.alert("特征距离必须是不小于0的数字")return end
if not path or path==""then gg.alert("保存位置不可为空")return end
if not name or name==""then gg.alert("文件名不可为空")return end
if path:sub(-1)~="/"then path=path.."/"end
return{distance=distance,path=path,name=name,file=path..name,format=format,step4=step4}end
local c=FeatureConfig()
if c then Config=c gg.alert("设置成功!\n"..c.file.."\n特征距离:≤"..c.distance.."\n偏移量进制:"..(c.format==1 and"10"or"16").."\n地址间隔:"..(c.step4 and"4"or"1"))end end
    function HS9()
gg.alert(gg.makeRequest("https://raw.githubusercontent.com/Lua39683512/GG-Reverse-Toolkit/main/Changelog.md").content,"v1.0.9")end
--====================================================
while true do--循环
if gg.isClickedUiButton()then Main0()end gg.sleep(100)end--检测res/drawable/ic_ui_button_24dp.png是否被点击,若被点击则打开Main0(),每次检测间隔100ms