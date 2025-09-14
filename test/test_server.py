import socket
import json
from datetime import datetime

def start_tcp_server(host='127.0.0.1', port=8080):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)
    print(f"TCP Server listening on {host}:{port}")
    
    conn, addr = server_socket.accept()
    print(f"Connection from {addr}")
    
    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            try:
                sensor_data = json.loads(data.decode())
                print(f"[{datetime.now()}] Received: {sensor_data}")
            except json.JSONDecodeError:
                print(f"Raw data: {data.decode()}")
    except KeyboardInterrupt:
        print("Server stopped")
    finally:
        conn.close()
        server_socket.close()

if __name__ == "__main__":
    start_tcp_server()