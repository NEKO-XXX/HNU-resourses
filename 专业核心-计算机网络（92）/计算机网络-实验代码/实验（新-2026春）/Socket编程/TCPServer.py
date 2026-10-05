from socket import *

serverPort = 12000
serverSocket = socket(AF_INET, SOCK_STREAM)
serverSocket.bind(('', serverPort))


serverSocket.listen(1)  # 将套接字设为被动监听模式，并指定“已完成连接队列”的最大长度为 1。
print(f"TCP Server is listening on port {serverPort}...")

# connectionSocket 是一个新的套接字对象，用于与客户端进行通信。clientAddress 是客户端的地址信息。
connectionSocket, clientAddress = serverSocket.accept()
print(f"Accepted connection from {clientAddress}")

message = connectionSocket.recv(1024).decode()
print(f"Received: {message}")
response = message.upper()
connectionSocket.send(response.encode())
print(f"Sent: {response}")

connectionSocket.close()
serverSocket.close()