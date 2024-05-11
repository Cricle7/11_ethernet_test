import socket

# 创建一个UDP套接字
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

host = '192.168.1.105'
port = 8081
s.bind((host, port))

# 接收数据
while True:
    data, addr = s.recvfrom(2048)  # 接收数据和客户端地址
    print(f"Received data from {addr}: {data.decode()}")

    # 判断接收到的数据是否为特定消息，如果是则跳出循环
    if data.strip() == b"quit":
        break

# 关闭套接字
s.close()