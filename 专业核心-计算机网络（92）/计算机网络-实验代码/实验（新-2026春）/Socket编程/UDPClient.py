from socket import *

serverName = '127.0.0.1'
serverPort = 12000
clientSocket = socket(AF_INET, SOCK_DGRAM)
# AF_INET 表示使用 IPv4 地址，SOCK_DGRAM 表示使用 UDP 协议。
# SOCK_DGRAM 使用无连接的 UDP 协议

# 显示 bind 指定的本地地址（IP 和临时端口）
clientSocket.bind(('', 5432))

message = input("Input lowercase sentence: ")
# 直接发送数据报
clientSocket.sendto(message.encode(), (serverName, serverPort))

# 打印本地套接字, sendto已经隐式绑定了一个本地端口，所以可以获取到本地地址信息
# 未 bind 时是临时端口；显式 bind 后就是固定的 5432。
local_ip, local_port = clientSocket.getsockname()
print(f"[Client local address: {local_ip}:{local_port}]\nMessage sent. Waiting for response...")

clientSocket.settimeout(2) # 设置超时 2 秒，若没有数据报到达则抛出 timeout。
try:
    modifiedMessage, serverAddress = clientSocket.recvfrom(2048)
    print(f"From Server: {modifiedMessage.decode()}")
except timeout:
    print("No response from server (timeout).")
except ConnectionResetError:
    print("No server listening on the destination port (connection reset).")
    # windwo 中, 若UDP连接没有找到目标服务器，会向源主机回复 ICMP 报告, recvfrom会抛出 ConnectionResetError
except Exception as e:
    print(f"An error occurred: {e}")
finally:
    clientSocket.close()
