from socket import *   # Python 标准套接字库，里面封装了操作系统底层的 socket 系统调用。

serverName = '127.0.0.1'
serverPort = 12000

clientSocket = socket(AF_INET, SOCK_STREAM)
# AF_INET 表示使用 IPv4 地址，SOCK_STREAM 表示使用 TCP 协议。
# 使用面向连接的 TCP 协议

try:
    # 进行三次握手
    clientSocket.connect((serverName, serverPort))

    # 成功建立连接
    print("Connected to server.")

    sentence = input("Input lowercase sentence: ")
    clientSocket.send(sentence.encode()) # 将字符串编码为字节串后发送给服务器

    modifiedSentence = clientSocket.recv(1024)  # 从服务器接收数据，参数 1024 表示一次最多接收 1024 字节
    print(f"From Server: {modifiedSentence.decode()}")

except ConnectionRefusedError as e:
    print(f"Connection failed. Is the server running ? [{e}]")
except Exception as e:
    print(f"An error occurred: {e}")
finally:
    clientSocket.close()
