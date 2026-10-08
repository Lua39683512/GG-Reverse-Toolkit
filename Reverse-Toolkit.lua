gg.showUiButton()--调用图片res/drawable/ic_ui_button_24dp.png
local DataType={D=true,F=true,E=true,Q=true,W=true,B=true,X=true}
local format=1
local Selected=nil
local Config={distance=8,path="/sdcard/",name="特征",file="/sdcard/特征",format=1}
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
local a=gg.prompt({"文件1","文件2","输出文件名","输出文件保存位置"},{"/sdcard","/sdcard","对比结果","/sdcard"},{"file","file","text","path"})
if not a then return end
local file1=a[1]
local file2=a[2]
local name=a[3]
local path=a[4]
if not file1 or file1==""then gg.alert("文件1不可为空")return end
if not file2 or file2==""then gg.alert("文件2不可为空")return end
if not name or name==""then gg.alert("文件名不可为空")return end
if not path or path==""then gg.alert("保存位置不可为空")return end
if path:sub(-1)~="/"then path=path.."/"end
local f1=io.open(file1,"r")
if not f1 then gg.alert("无法打开文件1:\n"..file1)return end
local f2=io.open(file2,"r")
if not f2 then f1:close()gg.alert("无法打开文件2:\n"..file2)return end
local list1={}
local list2={}
for line in f1:lines()do
list1[#list1+1]=line end
for line in f2:lines()do
list2[#list2+1]=line end
f1:close()
f2:close()
local function GetValue(line)
local t={}
local offset=line:match("A%[([^%]]+)%]")
for s in line:gmatch("[^;%s]+")do
if s:match("^[+-]?[%d,%.]+[DFEQWBX]$")or s:match("^[+-]?NaN[DFEQWBX]$")or s:match("^[+-]?Inf[DFEQWBX]$")then t[s]=true end end
return t,offset end
local result={}
local count=0
local max=math.min(#list1,#list2)
for i=1,max do
local a1,o1=GetValue(list1[i])
local a2,o2=GetValue(list2[i])
local same=false
local order={"D","F","E","W","B","Q","X"}--在偏移量后面加上相同的数据类型
local types={}
if o1==o2 then
for _,t in ipairs(order)do
for v in pairs(a1)do
if v:match("[DFEQWBX]$")==t and a2[v]then same=true types[#types+1]=t break end end end end
if same then result[#result+1]=list1[i]..table.concat(types,",")count=count+1 end end
local file=path..name
local f=io.open(file,"r")
if f then f:close()
local i=1
while true do
local newName=name.."("..i..")"
local newFile=path..newName
local f2=io.open(newFile,"r")
if f2 then f2:close()i=i+1 else file=newFile name=newName break end end end
local out=io.open(file,"w")
if not out then gg.alert("创建文件失败:\n"..file)return end
for _,line in ipairs(result)do
out:write(line,"\n")end
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
for offset=-distance,distance do
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
f:write(string.format("%X",address+o.offset),"\t",table.concat(line," ; "),"\tA[",offset,"]\n")
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
{"特征距离≤","特征文件保存位置","特征文件名称"},
{Config.distance,Config.path,Config.name},
{"","path","text"})
if not a then return end
local distance=tonumber(a[1])
local path=a[2]
local name=a[3]
if not distance or distance<0 then gg.alert("特征距离必须是不小于0的数字")return end
if not path or path==""then gg.alert("保存位置不可为空")return end
if not name or name==""then gg.alert("文件名不可为空")return end
if path:sub(-1)~="/"then path=path.."/"end
return{distance=distance,path=path,name=name,file=path..name,format=format}end
local c=FeatureConfig()
if c then Config=c gg.alert("设置成功!\n"..c.file.."\n特征距离:≤"..c.distance.."\n偏移量进制:"..(c.format==1 and"10"or"16"))end end
--====================================================
while true do--循环
if gg.isClickedUiButton()then Main0()end gg.sleep(100)end--检测res/drawable/ic_ui_button_24dp.png是否被点击,若被点击则打开Main0(),每次检测间隔100ms
