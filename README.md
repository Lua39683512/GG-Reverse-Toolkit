# Reverse-Toolkit
一个用于GameGuardian的Lua逆向分析工具箱
## 特点
- 数值的各种排版尽可能还原GameGuardian
- 可以自定义特征扫描的数据类型,文件保存位置等
## 主要功能
### 特征扫描
扫描选中数值周围的数值,写入到文件
### 对比特征
对比选中的两个特征文件,把有效的特征写入到对比文件
## 下载教程
方法1
1. 下载`Reverse-Toolkit.lua`
2. 使用GameGuardian执行
方法2
1. 下载`下载.lua`
2. 使用GameGuardian执行
3. 找到脚本下载的文件
4. 使用GameGuardian执行

## 注意事项
- 本工具需要 GameGuardian Lua 环境。
- 不同 GameGuardian 版本或修改版可能存在兼容性差异。
- 手动输入地址时，请确认地址及进制选择正确。
- 特征距离越大，需要读取的数据越多。
- 生成文件时，如果目标文件已经存在，工具会自动使用新的文件名。

开源项目

项目地址:https://github.com/Lua39683512/GG-Reverse-Toolkit
