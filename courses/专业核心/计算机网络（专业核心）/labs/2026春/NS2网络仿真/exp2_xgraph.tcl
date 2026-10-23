# 创建仿真器对象
set ns [new Simulator]

# 打开三个数据文件，分别记录三路流量的实时带宽（供 xgraph 绘制）
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]

# 循环创建 5 个节点 n(0) ~ n(4)
for {set i 0} {$i < 5} {incr i} {
    set n($i) [$ns node]
}

# 搭建星型拓扑：n0/n1/n2 → n3 → n4
$ns duplex-link $n(0) $n(3) 1Mb 100ms DropTail
$ns duplex-link $n(1) $n(3) 1Mb 100ms DropTail
$ns duplex-link $n(2) $n(3) 1Mb 100ms DropTail
$ns duplex-link $n(3) $n(4) 1Mb 100ms DropTail

# finish 过程：关闭数据文件，调用 xgraph 显示三条曲线
proc finish {} {
    global f0 f1 f2
    close $f0
    close $f1
    close $f2
    exec xgraph out0.tr out1.tr out2.tr -geometry 800x400 &   ;# xgraph 直接读取 .tr 文件绘图
    exit 0
}

# 封装函数：在指定节点上创建指数 ON/OFF 流量源
# Exponential 模型：burst_time_ 内以 rate_ 速率发包，idle_time_ 内静默
proc attach-expoo-traffic {node sink size burst idle rate} {
    set ns [Simulator instance]
    set source [new Agent/UDP]                             ;# 为节点创建 UDP 代理
    $ns attach-agent $node $source
    set traffic [new Application/Traffic/Exponential]      ;# 指数 ON/OFF 流量模型
    $traffic set packetSize_ $size                          ;# 数据包大小
    $traffic set burst_time_ $burst                         ;# 突发持续时间
    $traffic set idle_time_ $idle                           ;# 静默间隔
    $traffic set rate_ $rate                                ;# 突发期发送速率（峰率）
    $traffic attach-agent $source
    $ns connect $source $sink
    return $traffic
}

# 周期性采集带宽：每 0.5s 读取 LossMonitor 累计字节数，换算为 Mbps 后写入文件
proc record {} {
    global sink0 sink1 sink2 f0 f1 f2
    set ns [Simulator instance]
    set time 0.5                                           ;# 采样间隔 0.5s

    set bw0 [$sink0 set bytes_]     ;# 读取上周期累计字节数
    set bw1 [$sink1 set bytes_]
    set bw2 [$sink2 set bytes_]

    set now [$ns now]
    puts $f0 "$now [expr $bw0/$time*8/1000000]"            ;# 字节÷秒×8÷10^6 = Mbps
    puts $f1 "$now [expr $bw1/$time*8/1000000]"
    puts $f2 "$now [expr $bw2/$time*8/1000000]"

    $sink0 set bytes_ 0                                    ;# 清零，开始下一轮计数
    $sink1 set bytes_ 0
    $sink2 set bytes_ 0

    $ns at [expr $now+$time] "record"                      ;# 调度下一次采集
}

# 创建三个 LossMonitor 代理（只统计接收字节，不回复 ACK，适合 UDP 仿真）
set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
set sink2 [new Agent/LossMonitor]
$ns attach-agent $n(4) $sink0
$ns attach-agent $n(4) $sink1
$ns attach-agent $n(4) $sink2

# 三路流量：速率分别为 100k / 200k / 300k，包大小 200B，突发 2s / 空闲 1s
set source0 [attach-expoo-traffic $n(0) $sink0 200 2s 1s 100k]
set source1 [attach-expoo-traffic $n(1) $sink1 200 2s 1s 200k]
set source2 [attach-expoo-traffic $n(2) $sink2 200 2s 1s 300k]

# ----- 时序控制 -----
$ns at 0.0 "record"                   ;# 从 t=0 开始周期性采集带宽
$ns at 10.0 "$source0 start"          ;# 10s 三路同时启动
$ns at 10.0 "$source1 start"
$ns at 10.0 "$source2 start"
$ns at 50.0 "$source0 stop"           ;# 50s 三路同时停止
$ns at 50.0 "$source1 stop"
$ns at 50.0 "$source2 stop"
$ns at 60.0 "finish"                  ;# 60s 结束仿真

$ns run
