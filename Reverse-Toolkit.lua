gg.showUiButton()--调用图片res/drawable/ic_ui_button_24dp.png
local addressFormat=1
local Selected=nil
local TypeNames={[gg.TYPE_DWORD]="D",[gg.TYPE_FLOAT]="F",[gg.TYPE_DOUBLE]="E",[gg.TYPE_QWORD]="Q",[gg.TYPE_WORD]="W",[gg.TYPE_BYTE]="B",[gg.TYPE_XOR]="X"}
local function TypeName(f)return TypeNames[f]or"?"end
local Config={listTypes={{gg.TYPE_DWORD,"D"},{gg.TYPE_FLOAT,"F"},{gg.TYPE_DOUBLE,"E"},{gg.TYPE_WORD,"W"},{gg.TYPE_BYTE,"B"},{gg.TYPE_QWORD,"Q"},{gg.TYPE_XOR,"X"}},
DataType={D=true,F=true,E=true,Q=true,W=true,B=true,X=true},
format=1,distance=5000,path="/sdcard/",name="特征",file="/sdcard/特征",step=4,noComma=true}--保存HS2的输入
local CompareConfig={file1="/sdcard",file2="/sdcard",name="对比结果",path="/sdcard",ignore=""}--保存对比的输入
local ListConfig={showState=false,showValues=false,maxCount=10000}--保存HS10的输入
local FilterConfig={searchValue="",conditions="",replace=true,floatThreshold=0.001,useF=true,useE=true}--保存HS13的输入
local BaseConfig={depth=30,maxOffset=65535,limit=100000,offsetFormat=10,outputPath="/sdcard/",outputName="基址",output="/sdcard/基址"}--保存HS14的输入
------------------------------------------------------------------------------------------
local function FormatListValue(value)
if value==nil then return"?"end
local s=tostring(value)
local sign,integer,tail=s:match("^([+-]?)(%d+)(.*)$")
if integer and tail:match("^[%.%dEe%+%-]*$")then
integer=integer:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
s=sign..integer..tail end return s end
local function MakeSelectedMap(items)
local selected={}
if type(items)~="table"then return selected end
for _,v in ipairs(items)do
if v.address~=nil then
if v.flags~=nil then selected[tostring(v.address)..":"..tostring(v.flags)]=true else selected[tostring(v.address)]=true end end end return selected end
local function IsListSelected(selected,v)
if v.flags~=nil then return selected[tostring(v.address)..":"..tostring(v.flags)]==true end return selected[tostring(v.address)]==true end
local function GetDetailedValues(items)
local detailed={}
local batchSize=999
for first=1,#items,batchSize do
local last=math.min(first+batchSize-1,#items)
local request={}
for i=first,last do
for _,t in ipairs(Config.listTypes)do
request[#request+1]={address=items[i].address,flags=t[1]}end end
local values=gg.getValues(request)
if type(values)~="table"then return nil,tostring(values)end
for i=first,last do
local line={}
local base=(i-first)*#Config.listTypes
for j,t in ipairs(Config.listTypes)do
local v=values[base+j]
line[#line+1]=FormatListValue(v and v.value)..t[2]end
detailed[i]=table.concat(line,"; ")end end return detailed end
local function GetUniqueFilePath(path)--生成不重名的文件路径,不自动添加扩展名
local check=io.open(path,"rb")
if not check then return path end
check:close()
local i=1
while true do
local newPath=path.."("..i..")"
local f=io.open(newPath,"rb")
if not f then return newPath end
f:close()
i=i+1 end end
--====================================================
function SM(title,data,isMain)--增加一个函数"SM"用于优化菜单
local menu={}
for i,v in ipairs(data)do
menu[i]=v[1]end
if not isMain then menu[#menu+1]="回到主页"end--除了末尾有"true"以外的所有菜单末尾添加回到主页这个功能
local s=gg.choice(menu,"",title)
if s then
if s<=#data then data[s][2]()else Main0()end end end--点击回到主页这个功能后回到Main0()
--====================================================
    function Main0()
SM("",{
{"数值选择",Main2},
{"对比",Main3},
{"特征",Main1},
{"基址",Main4},
{"更新日志",HS9},
{"退出",HS0}
},true)end
    function Main2()
SM("",{
{"搜索列表",HS3},
{"保存列表",HS4},
{"地址",HS5},
{"设置",HS10}
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
if not s then return end Selected=r[s]end
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
if not s then return end Selected=r[s]end
    function HS5()
local a=gg.prompt({""},{},{""})
if not a then return end
local address
if addressFormat==1 then address=tonumber(a[1],16)else
local s=a[1]:gsub("^0[xX]","")
address=tonumber(s,10)end
if not address then gg.alert("格式错误")return end
Selected={address=address}end
     function HS10()
local a=gg.prompt(
{"显示勾选与冻结状态","数值详细显示","列表读取数量≤","地址进制"},
{ListConfig.showState,ListConfig.showValues,tostring(ListConfig.maxCount),addressFormat==1 and 16 or 10},
{"checkbox","checkbox","",""})
if not a then return end
local maxCount=tonumber(a[3])
if not maxCount or maxCount<1 or maxCount%1~=0 then gg.alert("列表读取数量必须是大于0的整数")return end
local radix=tonumber(a[4])
if radix~=16 and radix~=10 then gg.alert("地址进制只能是10或16")return end
ListConfig.showState=a[1]
ListConfig.showValues=a[2]
ListConfig.maxCount=maxCount
addressFormat=radix==16 and 1 or 2 end
    function Main3()
SM("",{
{"对比",HS1},
{"设置",HS6}
})end
    function HS1()
local a=gg.prompt(
{"文件1","文件2","输出文件名","输出文件保存位置"},
{CompareConfig.file1,CompareConfig.file2,CompareConfig.name,CompareConfig.path},
{"file","file","text","path"})
if not a then return end
if not a[1]or a[1]==""then gg.alert("文件1不可为空")return end
if not a[2]or a[2]==""then gg.alert("文件2不可为空")return end
if not a[3]or a[3]==""then gg.alert("文件名不可为空")return end
if not a[4]or a[4]==""then gg.alert("保存位置不可为空")return end
CompareConfig.file1=a[1]
CompareConfig.file2=a[2]
CompareConfig.name=a[3]
CompareConfig.path=a[4]
if a[4]:sub(-1)~="/"then a[4]=a[4].."/"end--确保保存路径以"/"结尾
local f1=io.open(a[1],"r")--打开对比文件
if not f1 then gg.alert("无法打开文件1")return end
local f2=io.open(a[2],"r")
if not f2 then f1:close()gg.alert("无法打开文件2")return end
local function DetectCompareFile(f)--根据第一条有效记录判断文件类型,基址文件以模块路径/开头,特征文件包含A[]
local pos=f:seek()
local kind
for line in f:lines()do
local text=line:match("^%s*(.-)%s*$")
if text~=""and text:sub(1,1)~="#"then
if text:sub(1,1)=="/"then kind="base"
elseif text:match("A%[([^%]]+)%]")then kind="feature"end break end end
f:seek("set",pos)return kind end
local fileType1=DetectCompareFile(f1)
local fileType2=DetectCompareFile(f2)
if not fileType1 or not fileType2 then f1:close()f2:close()gg.alert("无法识别文件")return end
if fileType1~=fileType2 then f1:close()f2:close()gg.alert("文件格式不一致")return end
if fileType1=="base"then--基址文件走基址对比逻辑
local function GetOffsetFormat(f)--读取第一条有效记录的模块偏移,判断偏移进制
local pos=f:seek()
local format
for line in f:lines()do
local text=line:match("^%s*(.-)%s*$")
if text~=""and text:sub(1,1)~="#"then
local offset=text:match("^[^|]*|([^|]+)|")
if offset then format=offset:match("^%s*0[xX]")and 16 or 10 end break end end
f:seek("set",pos)return format end
local format1=GetOffsetFormat(f1)
local format2=GetOffsetFormat(f2)
local sameFormat=format1~=nil and format1==format2
local function ParseOffset(value)--将10进制和16进制偏移统一转换为数值,用于不同进制文件之间的对比
value=value:match("^%s*(.-)%s*$")
local sign=1
local first=value:sub(1,1)
if first=="-"then sign=-1 value=value:sub(2)elseif first=="+"then value=value:sub(2)end
local number
if value:match("^0[xX]")then number=tonumber(value:sub(3),16)else number=tonumber(value,10)end
if not number or number%1~=0 then return nil end return sign*number end
local function NormalizeLine(line)
local module,moduleOffset,pointerOffsets,depth=line:match("^(.-)|([^|]+)|([^|]+)|(%d+)$")
if not module then return nil end
local base=ParseOffset(moduleOffset)
if base==nil then return nil end
local offsets={}
for part in(pointerOffsets..","):gmatch("(.-),")do
local number=ParseOffset(part)
if number==nil then return nil end
offsets[#offsets+1]=string.format("%.0f",number)end
if #offsets==0 then return nil end
return module.."|"..string.format("%.0f",base).."|"..table.concat(offsets,",").."|"..depth end
local function GetBaseKey(line)
if sameFormat then return line end
return NormalizeLine(line)end
local index={}
local count2=0
for line in f2:lines()do
if line~=""and line:sub(1,1)~="#"then
local key=GetBaseKey(line)
if key then index[key]=true count2=count2+1 end end end
f2:close()
local file=GetUniqueFilePath(a[4]..a[3])
local out=io.open(file,"w")
if not out then f1:close()gg.alert("创建文件失败:\n"..file)return end
local count1=0
local matched=0
for line in f1:lines()do
if line~=""and line:sub(1,1)~="#"then
local key=GetBaseKey(line)
if key then count1=count1+1
if index[key]then out:write(line,"\n")matched=matched+1 end end end end
f1:close()out:close()
gg.alert("文件1:"..count1.."条\n文件2:"..count2.."条\n共同:"..matched.."条\n文件:"..file)return end
------------------------------------------------------------------------------------------
local order={"D","F","E","W","B","Q","X"}
local validType={D=true,F=true,E=true,W=true,B=true,Q=true,X=true}
local function NormalizeOffset(s)--偏移量解析
if not s then return nil end
s=s:match("^%s*(.-)%s*$")--去除偏移量两端的空格
local sign=1--处理偏移量的正负号
local first=s:sub(1,1)
if first=="-"then sign=-1 s=s:sub(2)elseif first=="+"then s=s:sub(2)end
if s:match("^0[xX]")then--识别0x开头的16进制偏移量
local n=tonumber(s:sub(3),16)
if n then return sign*n end return nil end
local n=tonumber(s)--没有0x前缀按10进制解析
if n then return sign*n end return nil end
local function GetValueToken(s)
local typ=s:sub(-1)
if not validType[typ]then return nil end
local value=s:sub(1,-2):gsub(",","")
local lower=value:lower()
if lower=="nan"or lower=="+nan"or lower=="-nan"or lower=="inf"or lower=="+inf"or lower=="-inf"then return value..typ,typ end
if value:match("^[+-]?%d+%.?%d*[eE][+-]?%d+$")or value:match("^[+-]?%d+%.?%d*$")or value:match("^[+-]?%d*%.%d+$")then return value..typ,typ end return nil end
local function GetLineData(line)
local rawOffset=line:match("A%[([^%]]+)%]")--提取A[]中的偏移
local offset=NormalizeOffset(rawOffset)
if offset==nil then return nil,nil end--没有有效偏移量时跳过该行
local values={}
local body=line:gsub("A%[[^%]]+%]","")
body=body:match("^%s*%S+%s+(.+)$")or body
for s in body:gmatch("[^;%s]+")do
local token=GetValueToken(s)
if token then values[token]=true end end return values,offset end
local ignoreAny={}
local ignoreAnyText={}
local ignoreType={D={},F={},E={},W={},B={},Q={},X={}}
local ignoreTypeText={D={},F={},E={},W={},B={},Q={},X={}}
for part in((CompareConfig.ignore or"")..";"):gmatch("(.-);")do
part=part:match("^%s*(.-)%s*$")
if part~=""then
local typ=part:sub(-1):upper()
local value=part:sub(1,-2):gsub(",","")
local number=tonumber(value)
if typ=="A"then
if number~=nil then ignoreAny[number]=true else ignoreAnyText[value:lower()]=true end else
if number~=nil then ignoreType[typ][number]=true else ignoreTypeText[typ][value:lower()]=true end end end end
local function IsIgnored(token)
local typ=token:sub(-1)
local value=token:sub(1,-2)
local number=tonumber(value)
if number~=nil then
return ignoreAny[number]or(ignoreType[typ]and ignoreType[typ][number])or false end
value=value:lower()
return ignoreAnyText[value]or(ignoreTypeText[typ]and ignoreTypeText[typ][value])or false end
local index2={}--逐行读取文件2只保留偏移量和对应的数值索引
local count2=0
for line in f2:lines()do--根据HS6决定是否创建索引
count2=count2+1
local values,offset=GetLineData(line)
if offset~=nil then
local target=index2[offset]
for token in pairs(values)do
if not IsIgnored(token)then
if not target then target={}index2[offset]=target end target[token]=true end end end end
f2:close()
local file=a[4]..a[3]--生成不重名的输出文件
local check=io.open(file,"r")
if check then
check:close()
local i=1
while true do
local newFile=a[4]..a[3].."("..i..")"
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
local matchedTypes={}
for token in pairs(values1)do
if values2[token]then matchedTypes[token:sub(-1)]=true end end
local types={}
for _,typ in ipairs(order)do
if matchedTypes[typ]then types[#types+1]=typ end end
if #types>0 then out:write(line,table.concat(types,","),"\n")count=count+1 end end end
f1:close()out:close()
gg.alert("文件1行数:"..count1.."\n文件2行数:"..count2.."\n保留:"..count.."行\n文件:"..file)end
    function HS6()
local a=gg.prompt(
{"特征对比忽略相同值(数值+数据类型;数值+数据类型,例如:0A;1D;5F)"},
{CompareConfig.ignore or""},
{""})
if not a then return end
local validType={A=true,D=true,F=true,E=true,W=true,B=true,Q=true,X=true}
for part in ((a[1]or"")..";"):gmatch("(.-);")do
part=part:match("^%s*(.-)%s*$")
if part~=""then
local typ=part:sub(-1):upper()
local value=part:sub(1,-2):gsub(",","")
local lower=value:lower()
local validValue=tonumber(value)~=nil or lower=="nan"or lower=="+nan"or lower=="-nan"or lower=="inf"or lower=="+inf"or lower=="-inf"
if not validType[typ]or value==""or not validValue then gg.alert("格式错误")return end end end
CompareConfig.ignore=a[1]or""end
    function Main1()
SM("",{
{"扫描",HS8},
{"测试",HS13},
{"设置",HS2}
})end
    function HS8()
if not Selected then gg.alert("数值未选择")return end
local types={}
if Config.DataType.D then types[#types+1]={gg.TYPE_DWORD,"D"}end
if Config.DataType.F then types[#types+1]={gg.TYPE_FLOAT,"F"}end
if Config.DataType.E then types[#types+1]={gg.TYPE_DOUBLE,"E"}end
if Config.DataType.W then types[#types+1]={gg.TYPE_WORD,"W"}end
if Config.DataType.B then types[#types+1]={gg.TYPE_BYTE,"B"}end
if Config.DataType.Q then types[#types+1]={gg.TYPE_QWORD,"Q"}end
if Config.DataType.X then types[#types+1]={gg.TYPE_XOR,"X"}end
local address=Selected.address
local distance=Config.distance
local request={}
local offsetList={}
local step=Config.step
local maxOffset=math.floor(distance/step)*step
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
if Config.noComma then return s end
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
if Config.format==1 then offset=string.format("%.0f",o.offset)else
if o.offset<0 then offset="-0x"..string.format("%X",-o.offset)else offset="0x"..string.format("%X",o.offset)end end
f:write(string.format("%X",address+o.offset),"    ",table.concat(line,"  ;  "),"    A[",offset,"]\n")
count=count+1 end end
f:close()
gg.alert("生成:"..count.."行\n文件:"..Config.file)end
    function HS13()
local a=gg.prompt(
{"搜索值(数值+类型,例如:1D)","过滤条件(偏移量+数据类型+数值;偏移量+数据类型+数值,例如:-4F5;0x4Q7)","将符合条件的结果替换搜索结果","浮点误差阈值","F类型误差","E类型误差"},
{FilterConfig.searchValue,FilterConfig.conditions,FilterConfig.replace,FilterConfig.floatThreshold,FilterConfig.useF,FilterConfig.useE},
{"","","checkbox","","checkbox","checkbox"})
if not a then return end
local threshold=tonumber(a[4])or 0.001
if threshold<=0 then gg.alert("浮点误差必须大于0")return end
FilterConfig.searchValue=a[1]
FilterConfig.conditions=a[2]
FilterConfig.replace=a[3]
FilterConfig.floatThreshold=threshold
FilterConfig.useF=a[5]
FilterConfig.useE=a[6]
local TypeMap={D=gg.TYPE_DWORD,F=gg.TYPE_FLOAT,E=gg.TYPE_DOUBLE,Q=gg.TYPE_QWORD,W=gg.TYPE_WORD,B=gg.TYPE_BYTE,X=gg.TYPE_XOR}
local function Trim(s)
return tostring(s or""):match("^%s*(.-)%s*$")end
local function ParseTypedValue(s)--解析数值+数据类型
s=Trim(s)
local typ=s:sub(-1):upper()
local flag=TypeMap[typ]
if not flag then return nil end
local value=s:sub(1,-2):gsub("%s",""):gsub(",","")
local number=tonumber(value)
if not number then return nil end return value,flag,number,typ end
local function ParseOffset(s)--解析偏移量,支持正负数10和16进制
s=Trim(s):gsub("%s","")
local sign=1
local first=s:sub(1,1)
if first=="-"then sign=-1 s=s:sub(2)elseif first=="+"then s=s:sub(2)end
local n
if s:match("^0[xX]")then n=tonumber(s:sub(3),16)else n=tonumber(s)end
if not n or n%1~=0 then return nil end return sign*n end
local searchValue,searchFlag=ParseTypedValue(a[1])
if not searchValue then gg.alert("搜索值格式错误,请使用5F等格式")return end
if not a[2] or Trim(a[2])==""then gg.alert("过滤条件不可为空")return end
local conditions={}--解析过滤条件
for part in (a[2]..";"):gmatch("(.-);")do
if Trim(part)~=""then
local offsetText,flagText,valueText=part:match("^%s*([+-]?[%w]+)([DFEWBQX])%s*(.-)%s*$")
if not offsetText or not valueText or Trim(valueText)==""then gg.alert("过滤条件格式错误：\n"..part)return end
local typedText=Trim(valueText)..flagText
local offset=ParseOffset(offsetText)
if offset==nil then gg.alert("偏移量格式错误:\n"..offsetText)return end
local value,flag,target,typ=ParseTypedValue(typedText)
if not value then gg.alert("过滤数值格式错误:\n"..typedText)return end
conditions[#conditions+1]={offset=offset,flag=flag,target=target,typ=typ}end end
if #conditions==0 then gg.alert("至少需要1个过滤条件")return end
gg.clearResults()gg.searchNumber(searchValue,searchFlag)--搜索指定数值
local total=gg.getResultsCount()
if total==0 then gg.alert("没有搜索到结果")return end
local batchSize=519000
local found=0
local filteredResults=a[3]and{}or nil
for skip=0,total-1,batchSize do--分批读取搜索结果
local count=math.min(batchSize,total-skip)
local current=gg.getResults(count,skip)
if type(current)~="table"or#current~=count then gg.alert("读取搜索结果失败\n位置:"..skip)return end
for _,cond in ipairs(conditions)do--对当前批次逐条件筛选
if #current==0 then break end
local request={}
for i=1,#current do
request[i]={address=current[i].address+cond.offset,flags=cond.flag}end
local ok,read=pcall(gg.getValues,request)
if not ok or type(read)~="table"or#read~=#current then gg.alert("读取过滤数值失败\n偏移量:"..cond.offset)return end
local pass={}
local pc=0
for i=1,#current do
local actual=read[i] and tonumber(read[i].value)
local matched=false
if actual~=nil then
if cond.typ=="F"then--浮点数误差
if FilterConfig.useF then matched=actual==actual and math.abs(actual-cond.target)<FilterConfig.floatThreshold else matched=actual==cond.target end
elseif cond.typ=="E"then
if FilterConfig.useE then matched=actual==actual and math.abs(actual-cond.target)<FilterConfig.floatThreshold else matched=actual==cond.target end else matched=actual==cond.target end
if matched then pc=pc+1 pass[pc]=current[i]end end end
current=pass end
found=found+#current--累计匹配数量
if filteredResults then--只有勾选替换时才保存匹配结果
for i=1,#current do
filteredResults[#filteredResults+1]=current[i]end end end
if a[3]then gg.clearResults()--a[3]决定是否替换搜索结果
if #filteredResults>0 then
local ok,result=pcall(gg.loadResults,filteredResults)
if not ok or result==false or type(result)=="string"then gg.alert("加载筛选结果失败")return end end end
if not a[3]then gg.alert("找到"..found.."个")end end--若a[3]为true则不gg.alert()
    function HS2()
local typeOrder={"D,F,E,W,B,Q,X"}
local validTypes={D=true,F=true,E=true,W=true,B=true,Q=true,X=true}
local typeText={}
for typ in typeOrder[1]:gmatch("[^,]+")do
if Config.DataType[typ]then typeText[#typeText+1]=typ end end
local a=gg.prompt(
{"数据类型","偏移量进制","特征距离≤","特征文件保存位置","特征文件名称","地址距离","数值不添加千位分隔符"},
{table.concat(typeText,","),Config.format==1 and 10 or 16,Config.distance,Config.path,Config.name,Config.step,Config.noComma},
{"","","","path","text","","checkbox"})
if not a then return end
local selectedTypes={}
for part in (tostring(a[1]or"")..","):gmatch("(.-),")do
part=part:match("^%s*(.-)%s*$"):upper()
if not validTypes[part]then gg.alert("数据类型格式错误")return end selectedTypes[part]=true end
if not next(selectedTypes)then gg.alert("至少选择一种数据类型")return end
local radix=tonumber(a[2])
if radix~=10 and radix~=16 then gg.alert("偏移量进制只能是10或16")return end
local distance=tonumber(a[3])
if not distance or distance<0 or distance%1~=0 then gg.alert("特征距离必须是不小于0的整数")return end
local step=tonumber(a[6])
if not step or step<1 or step%1~=0 then gg.alert("地址距离必须是大于0的整数")return end
if not a[4]or a[4]==""then gg.alert("保存位置不可为空")return end
if not a[5]or a[5]==""then gg.alert("文件名不可为空")return end
if a[4]:sub(-1)~="/"then a[4]=a[4].."/"end
for typ in typeOrder[1]:gmatch("[^,]+")do
Config.DataType[typ]=selectedTypes[typ]==true end
Config.format=radix==10 and 1 or 2
Config.distance=distance
Config.path=a[4]
Config.name=a[5]
Config.file=a[4]..a[5]
Config.step=step
Config.noComma=a[7]end
    function Main4()
SM("",{
{"扫描",HS14},
{"设置",HS17}
})end
    function HS17()
local a=gg.prompt(
{"扫描深度","最大指针偏移","文件保存位置","文件名","偏移量进制"},
{BaseConfig.depth,BaseConfig.maxOffset,BaseConfig.outputPath,BaseConfig.outputName,BaseConfig.offsetFormat or 10},
{"","","path","text",""})
if not a then return end
local depth=tonumber(a[1])
if not depth or depth<1 or depth>30 or depth%1~=0 then gg.alert("扫描深度必须是1到30之间的整数")return end
local maxOffset=tonumber(a[2])
if not maxOffset or maxOffset<1 or maxOffset>65535 or maxOffset%1~=0 then gg.alert("最大指针偏移必须是大于0小于65535的整数")return end
if not a[3]or a[3]==""then gg.alert("基址文件保存位置不可为空")return end
if not a[4]or a[4]==""then gg.alert("基址文件名不可为空")return end
local radix=tonumber(a[5])
if radix~=10 and radix~=16 then gg.alert("偏移量进制只能是10或16")return end
if a[3]:sub(-1)~="/"then a[3]=a[3].."/"end
BaseConfig.depth=depth
BaseConfig.maxOffset=maxOffset
BaseConfig.outputPath=a[3]
BaseConfig.outputName=a[4]
BaseConfig.output=a[3]..a[4]
BaseConfig.offsetFormat=radix end
    function HS14()
if not Selected or not Selected.address then gg.alert("数值未选择")return end--只使用Main2选中的数值,不再读取GG勾选列表或要求手动指定模块
local targetAddress=Selected.address
local depth=BaseConfig.depth
local maxOffset=BaseConfig.maxOffset
if not depth or depth<1 or depth>30 or depth%1~=0 then gg.alert("扫描深度必须是大于0小于30的整数")return end
if not maxOffset or maxOffset<0 or maxOffset>65535 or maxOffset%1~=0 then gg.alert("最大指针偏移必须是大于0小于65535的整数")return end
local output=BaseConfig.output
if not output or output==""then gg.alert("请先在基址设置中设置文件保存位置和文件名")return end
output=GetUniqueFilePath(output)--文件已存在时防止重名
local ok,ranges=pcall(gg.getRangesList)--获取当前进程的全部命名内存映射,后续自动判断基址属于哪个模块
if not ok or type(ranges)~="table"then gg.alert("获取内存映射失败:\n"..tostring(ranges))return end
local moduleMap={}
local moduleRanges={}
for _,v in ipairs(ranges)do
local name=v.name
if type(name)~="string"or name==""or name:sub(1,1)=="["then name=v.internalName end
if type(name)=="string"and name~=""and name:sub(1,1)~="["and name:lower():match("%.so")and v.start and v["end"]then
local g=moduleMap[name]
if not g then g={name=name,base=v.start}moduleMap[name]=g elseif v.start<g.base then g.base=v.start end
moduleRanges[#moduleRanges+1]={start=v.start,finish=v["end"],module=g}end end
if #moduleRanges==0 then gg.alert("没有找到可作为基址的模块映射")return end
table.sort(moduleRanges,function(x,y)return x.start<y.start end)--按起始地址排序,便于通过二分查找确定候选指针属于哪个模块
local function FindModule(address)
local low,high=1,#moduleRanges
while low<=high do
local mid=math.floor((low+high)/2)
local v=moduleRanges[mid]
if address<v.start then high=mid-1 elseif address>=v.finish then low=mid+1 else return v.module end end return nil end
local f=io.open(output,"w")
if not f then gg.alert("无法创建文件:\n"..output)return end
local info=gg.getTargetInfo()or{}
local pointerFlag=info.x64 and gg.TYPE_QWORD or gg.TYPE_DWORD
local seedFrontier={{address=targetAddress,chain={}}}
local function FormatHex(n)
if n<0 then return"-0x"..string.format("%X",-n)end return"0x"..string.format("%X",n)end
local function FormatBaseOffset(n)
if BaseConfig.offsetFormat==10 then return string.format("%.0f",n)end return FormatHex(n)end
local function FindParents(nodes,value)
local low,high=1,#nodes--从当前层目标地址中寻找与指针值距离不超过最大偏移的候选父节点
while low<=high do
local mid=math.floor((low+high)/2)
if nodes[mid].address<value then low=mid+1 else high=mid-1 end end
local left,right=low-1,low
local parents={}
while #parents<99 do
local leftDistance=left>=1 and math.abs(nodes[left].address-value)or math.huge
local rightDistance=right<=#nodes and math.abs(nodes[right].address-value)or math.huge
if math.min(leftDistance,rightDistance)>maxOffset then break end
if leftDistance<=rightDistance then parents[#parents+1]=nodes[left]left=left-1 else parents[#parents+1]=nodes[right]right=right+1 end end return parents end
local frontier=seedFrontier
local found=0
local foundMap={}
local finished=0
local failed
for level=1,depth do
if #frontier==0 then break end
table.sort(frontier,function(x,y)return x.address<y.address end)--按地址排序,便于通过指针值快速定位上一层节点
local seed={}
for i,v in ipairs(frontier)do seed[i]={address=v.address,flags=pointerFlag}end
gg.clearResults()
local ok,result=pcall(gg.loadResults,seed)
if not ok or result==false or type(result)=="string"then failed="加载第"..level.."层搜索目标失败:"..tostring(result)break end
local ok2,result2=pcall(gg.searchPointer,maxOffset,0,-1,BaseConfig.limit)
if not ok2 or result2~=true then failed="第"..level.."层指针搜索失败:"..tostring(result2)break end
local count=gg.getResultsCount()
if count==0 then break end
local current=gg.getResults(math.min(count,BaseConfig.limit))
if type(current)~="table"then failed="读取第"..level.."层搜索结果失败"break end
local nextFrontier={}
local nextSeen={}
for _,v in ipairs(current)do
local value=tonumber(v.value)
if value and v.address then
local parents=FindParents(frontier,value)
for _,parent in ipairs(parents)do
local offset=parent.address-value
local chain={offset}
for i=1,#parent.chain do chain[#chain+1]=parent.chain[i]end
local offsetText={}
for i,n in ipairs(chain)do offsetText[i]=FormatBaseOffset(n)end
local module=FindModule(v.address)--候选指针存储位置属于某个命名模块时,将该模块作为基址并记录结果
if module then
local moduleOffset=v.address-module.base
local row=module.name.."|"..FormatBaseOffset(moduleOffset).."|"..table.concat(offsetText,",").."|"..level
if not foundMap[row]then
foundMap[row]=true
f:write(row,"\n")
found=found+1 end end
if #nextFrontier<BaseConfig.limit then--无论是否找到模块,都继续向上一层搜索
local key=tostring(v.address)..":"..table.concat(offsetText,",")
if not nextSeen[key]then
nextSeen[key]=true
nextFrontier[#nextFrontier+1]={address=v.address,chain=chain}
end end
if #nextFrontier>=BaseConfig.limit then break end end end end
frontier=nextFrontier
finished=level
gg.toast("基址扫描"..level.."/"..depth.."层|目标:"..#frontier.."|候选:"..count.."|找到:"..found,true)end
f:close()
gg.alert("找到:"..found.."条\n文件:"..output)end
    function HS9()
gg.alert(gg.makeRequest("https://raw.githubusercontent.com/Lua39683512/GG-Reverse-Toolkit/main/Changelog.md").content,"v1.2.1")end
--====================================================
while true do--循环
if gg.isClickedUiButton()then Main0()end gg.sleep(100)end--检测res/drawable/ic_ui_button_24dp.png是否被点击,若被点击则打开Main0(),每次检测间隔100ms
