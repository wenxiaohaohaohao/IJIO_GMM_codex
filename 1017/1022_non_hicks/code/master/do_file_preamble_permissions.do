*============================================================================
* do_file_preamble_permissions.do
* 目的：在任何输出操作前，清除只读属性（可选）
* 使用方法：在主脚本开始处 include 这个文件
*============================================================================

* 方法1：使用 shell 命令（如果 Windows 系统）
* 递归移除 results 目录的只读属性
capture noisily shell attrib -r "$RES_DATA\*.dta" /s
capture noisily shell attrib -r "$RES_LOG\*.log" /s

* 方法2：使用 shell 命令移除整个目录树的只读属性
capture noisily shell attrib -r "$RES_DATA" /s /d
capture noisily shell attrib -r "$RES_LOG" /s /d
capture noisily shell attrib -r "$DATA_WORK" /s /d

di "✓ 已清除只读属性"
