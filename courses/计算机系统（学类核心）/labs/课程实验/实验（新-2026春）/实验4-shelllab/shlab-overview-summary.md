# Lab Assignment: Writing Your Own Shell (ShLab) - 总结

## 1. 实验目的

通过编写一个支持作业控制（job control）的简单 Unix Shell 程序，熟悉**进程控制**和**信号处理**的概念。

## 2. 实验准备

1. 拷贝 `shlab-handout.tar` 到实验目录
2. `tar xvf shlab-handout.tar` 解压
3. `make` 编译测试例程
4. 在 `tsh.c` 顶部注释中填写团队成员姓名和 Andrew ID

## 3. 需要实现的函数（tsh.c）

| 函数 | 功能 | 参考代码行数 |
|------|------|-------------|
| `eval` | 解析并执行命令行 | ~70 行 |
| `builtin_cmd` | 识别并处理内置命令（quit, fg, bg, jobs） | ~25 行 |
| `do_bgfg` | 实现 bg 和 fg 内置命令 | ~50 行 |
| `waitfg` | 等待前台作业完成 | ~20 行 |
| `sigchld_handler` | 捕获 SIGCHLD 信号 | ~80 行 |
| `sigint_handler` | 捕获 SIGINT（ctrl-c）信号 | ~15 行 |
| `sigtstp_handler` | 捕获 SIGTSTP（ctrl-z）信号 | ~15 行 |

每次修改后执行 `make` 重新编译，运行 `./tsh` 启动 Shell。

## 4. Unix Shell 基本概念

- **Shell** 是交互式命令行解释器，循环打印提示符 → 读取命令 → 执行操作
- 命令行由空格分隔的 ASCII 文本组成，第一个词是内置命令名或可执行文件路径
- **内置命令**：在当前进程中立即执行
- **外部程序**：fork 子进程，在子进程中加载运行。一个命令行产生的子进程集合称为一个**作业（job）**
- 以 `&` 结尾 → **后台运行**（Shell 不等待，继续接受下一条命令）
- 不以 `&` 结尾 → **前台运行**（Shell 等待作业终止后才接受新命令）

## 5. 作业控制（Job Control）

- **ctrl-c** → 向前台作业每个进程发 SIGINT（默认：终止进程）
- **ctrl-z** → 向前台作业每个进程发 SIGTSTP（默认：停止进程，等待 SIGCONT 唤醒）
- **jobs**：列出所有后台作业
- **bg \<job\>**：将停止的后台作业恢复为运行中的后台作业
- **fg \<job\>**：将停止/运行中的后台作业切换到前台运行
- **kill \<job\>**：终止作业

## 6. tsh Shell 规范

- 提示符：`tsh> `
- 不需要支持管道（`|`）和 I/O 重定向（`<` `>`）
- 支持 PID 和 JID（`%` 前缀）两种方式标识作业
- 支持内置命令：`quit`、`jobs`、`bg <job>`、`fg <job>`
- 必须回收所有僵尸子进程；若作业因未捕获的信号终止，需打印消息（含 PID 和信号描述）

## 7. 测试工具

- **tshref**：参考解决方案，你的 Shell 应产生相同输出（PID 除外）
- **sdriver.pl**：Shell 驱动程序，按 trace 文件发送命令和信号
- **16 个 trace 文件**（trace01.txt ~ trace16.txt）：从简单到复杂的测试用例
- 使用方法：
  - `./sdriver.pl -t trace01.txt -s ./tsh -a "-p"` 或 `make test01`
  - `./sdriver.pl -t trace01.txt -s ./tshref -a "-p"` 或 `make rtest01`
- `tshref.out` 包含参考方案所有测试的输出

## 8. 实现提示

- **信号阻塞**：在 `eval` 中，父进程在 fork 前必须用 `sigprocmask` 阻塞 SIGCHLD，在调用 `addjob` 后再解除阻塞，避免竞争条件
- **子进程**：必须在 exec 新程序前解除 SIGCHLD 阻塞
- **waitfg 与 sigchld_handler 分工**：
  - `waitfg`：用 sleep 忙等循环
  - `sigchld_handler`：仅调用一次 `waitpid` 完成回收
- **信号发送**：向整个前台进程组发信号时，使用 `-pid` 而非 `pid` 作为 kill 参数
- **进程组隔离**：fork 后、execve 前，子进程调用 `setpgid(0, 0)` 将自身放入新进程组（组 ID = PID），确保 ctrl-c 只发给前台作业而非 Shell 本身
- 先阅读 Chapter 8（异常控制流）
- 按 trace01 → trace02 → ... 顺序逐步开发
- 关键函数：`waitpid`、`kill`、`fork`、`execve`、`setpgid`、`sigprocmask`（以及 `WUNTRACED`、`WNOHANG` 选项）
- 不要在 Shell 中运行 more、less、vi、emacs 等终端控制程序，只用简单程序如 `/bin/ls`、`/bin/ps`、`/bin/echo`
