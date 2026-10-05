# 创建仿真器对象
set ns [new Simulator]

# 定义流量颜色：flow 1 = Blue, flow 2 = Red（在 NAM 中显示）
$ns color 1 Blue
$ns color 2 Red

# 打开 NAM 轨迹文件（记录所有数据包事件：s 发送/r 接收/d 丢弃）
set nf [open out.nam w]
$ns namtrace-all $nf

# finish 过程：仿真结束时自动打开 NAM
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam out.nam &
    exit 0
}

# 创建 4 个网络节点
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

# 建立双向链路（带宽 1Mb，延迟 10ms，队列类型 DropTail）
$ns duplex-link $n0 $n2 1Mb 10ms DropTail
$ns duplex-link $n1 $n2 1Mb 10ms DropTail
$ns duplex-link $n2 $n3 1Mb 10ms DropTail

# 设置 NAM 中节点的排列方向（美观排版）
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right

# ----- 第一条流：n0 → n3 -----
set udp0 [new Agent/UDP]          ;# 创建 UDP 代理
$udp0 set class_ 1                ;# 关联颜色 class 1（Blue）
$ns attach-agent $n0 $udp0        ;# 将代理绑定到节点 n0

set cbr0 [new Application/Traffic/CBR]   ;# CBR = 恒定比特率流量
$cbr0 set packetSize_ 500                 ;# 每包 500 字节
$cbr0 set interval_ 0.005                 ;# 发送间隔 0.005s（≈ 800kbps）
$cbr0 attach-agent $udp0

# ----- 第二条流：n1 → n3 -----
set udp1 [new Agent/UDP]
$udp1 set class_ 2                ;# 关联颜色 class 2（Red）
$ns attach-agent $n1 $udp1

set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 500
$cbr1 set interval_ 0.005
$cbr1 attach-agent $udp1

# ----- 接收端（n3）-----
set null0 [new Agent/Null]        ;# Null 代理：接收数据包并直接丢弃（不回复 ACK）
$ns attach-agent $n3 $null0

# 连接发送端与接收端
$ns connect $udp0 $null0
$ns connect $udp1 $null0

# ----- 时序控制（$ns at 时间 "动作"）-----
$ns at 0.5 "$cbr0 start"          ;# 0.5s 启动流 0
$ns at 1.0 "$cbr1 start"          ;# 1.0s 启动流 1
$ns at 4.0 "$cbr1 stop"           ;# 4.0s 停止流 1
$ns at 4.5 "$cbr0 stop"           ;# 4.5s 停止流 0
$ns at 5.0 "finish"               ;# 5.0s 结束仿真

$ns run                            ;# 启动离散事件仿真引擎
