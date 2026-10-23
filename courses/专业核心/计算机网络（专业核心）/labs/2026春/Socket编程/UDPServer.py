from socket import *

serverPort = 12000
serverSocket = socket(AF_INET, SOCK_DGRAM)

serverSocket.bind(('', serverPort))  # 将套接字绑定到本地地址和端口，显示绑定到12000端口
print(f"UDP Server is ready on port {serverPort}...")

while True:
    message, clientAddress = serverSocket.recvfrom(2048) # recfrom能够直接返回客户端的地址信息
    # clientAddress 是一个元组，从报文获取客户端的 IP 地址和端口号。
    print(f"Received from {clientAddress}: {message.decode()}")

    response = message.decode().upper()

    serverSocket.sendto(response.encode(), clientAddress)
    print(f"Sent back: {response}")