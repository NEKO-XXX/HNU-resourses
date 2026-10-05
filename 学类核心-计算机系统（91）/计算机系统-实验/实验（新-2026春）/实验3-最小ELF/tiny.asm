; tiny.asm
BITS 32          ; 指定生成 32 位代码
GLOBAL _start    ; 声明 _start 为全局入口, 使得后面的ld知道程序入口在哪
; 这样的信息后续会被 strip 指令删除, 不会进入到最终的可执行文件
SECTION .text    ; 声明接下来的代码放入.text 节

_start:
    mov eax, 1        ; exit 系统调用号, 固定为 1 (5字节)
    mov ebx, 040413   ; 程序的返回值 (5字节)
    int 0x80          ; 触发 Linux 系统调用(2字节)