#!/usr/bin/env python3
"""
Motion Sensor Stream Client
Connects to the Flutter app's live sensor data stream
"""

import socketio
import json
import time
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from collections import deque
import threading
import numpy as np

class MotionSensorClient:
    def __init__(self, host='127.0.0.1', port=8080):
        self.host = host
        self.port = port
        self.sio = socketio.Client()
        
        # Data storage for plotting
        self.accel_data = deque(maxlen=100)
        self.gyro_data = deque(maxlen=100)
        self.timestamps = deque(maxlen=100)
        self.current_activity = "Unknown"
        self.elapsed_seconds = 0
        
        # Setup matplotlib for real-time plotting
        self.fig, (self.ax1, self.ax2) = plt.subplots(2, 1, figsize=(12, 8))
        self.fig.suptitle('Live Motion Sensor Data Stream')
        
        # Setup event handlers
        self._setup_event_handlers()
        
    def _setup_event_handlers(self):
        @self.sio.event
        def connect():
            print(f'Connected to {self.host}:{self.port}')
            
        @self.sio.event
        def disconnect():
            print('Disconnected from server')
            
        @self.sio.event
        def sensor_data(data):
            """Handle incoming sensor data"""
            try:
                # Parse JSON data
                sensor_info = json.loads(data)
                
                # Extract data
                timestamp = sensor_info.get('timestamp')
                sensor_data = sensor_info.get('data', {})
                device_info = sensor_info.get('device_info', {})
                
                # Store sensor readings
                if 'sensor_type' in sensor_data:
                    sensor_type = sensor_data['sensor_type']
                    magnitude = sensor_data.get('magnitude', 0)
                    self.current_activity = sensor_data.get('current_activity', 'Unknown')
                    self.elapsed_seconds = sensor_data.get('elapsed_seconds', 0)
                    
                    # Store data for plotting
                    current_time = time.time()
                    self.timestamps.append(current_time)
                    
                    if sensor_type == 'accelerometer':
                        self.accel_data.append(magnitude)
                    elif sensor_type == 'gyroscope':
                        self.gyro_data.append(magnitude)
                
                # Print periodic status
                if len(self.timestamps) % 50 == 0:  # Every 50 data points
                    print(f"Activity: {self.current_activity}, "
                          f"Elapsed: {self.elapsed_seconds}s, "
                          f"Data points: {len(self.timestamps)}")
                    
            except json.JSONDecodeError as e:
                print(f"Error parsing sensor data: {e}")
            except Exception as e:
                print(f"Error handling sensor data: {e}")
    
    def connect(self):
        """Connect to the sensor stream server"""
        try:
            url = f'http://{self.host}:{self.port}'
            print(f"Attempting to connect to {url}")
            self.sio.connect(url, transports=['websocket'])
            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from server"""
        self.sio.disconnect()
    
    def start_plotting(self):
        """Start real-time plotting"""
        def update_plot(frame):
            if len(self.timestamps) == 0:
                return
            
            # Convert timestamps to relative time
            if len(self.timestamps) > 1:
                time_axis = np.array([t - self.timestamps[0] for t in self.timestamps])
            else:
                time_axis = np.array([0])
            
            # Clear and plot accelerometer data
            self.ax1.clear()
            if len(self.accel_data) > 0:
                accel_array = np.array(list(self.accel_data))
                self.ax1.plot(time_axis[-len(accel_array):], accel_array, 'b-', linewidth=2, label='Accelerometer')
                self.ax1.set_ylabel('Magnitude (m/s²)')
                self.ax1.legend()
                self.ax1.grid(True)
                self.ax1.set_title(f'Accelerometer - Activity: {self.current_activity} ({self.elapsed_seconds}s)')
            
            # Clear and plot gyroscope data
            self.ax2.clear()
            if len(self.gyro_data) > 0:
                gyro_array = np.array(list(self.gyro_data))
                self.ax2.plot(time_axis[-len(gyro_array):], gyro_array, 'r-', linewidth=2, label='Gyroscope')
                self.ax2.set_ylabel('Magnitude (rad/s)')
                self.ax2.set_xlabel('Time (seconds)')
                self.ax2.legend()
                self.ax2.grid(True)
                self.ax2.set_title('Gyroscope')
            
            # Adjust layout
            self.fig.tight_layout()
        
        # Start animation
        ani = FuncAnimation(self.fig, update_plot, interval=100, blit=False)
        plt.show()
        return ani

def main():
    # Configuration
    HOST = '127.0.0.1'  # Change to your device's IP if running on different machine
    PORT = 8080         # Must match the port in your Flutter app settings
    
    print("Motion Sensor Stream Client")
    print(f"Connecting to {HOST}:{PORT}")
    print("Make sure your Flutter app is running and streaming is enabled!")
    print("-" * 60)
    
    # Create client
    client = MotionSensorClient(host=HOST, port=PORT)
    
    # Connect to server
    if not client.connect():
        print("Failed to connect. Please check:")
        print("1. Flutter app is running")
        print("2. Streaming is enabled in settings")
        print("3. Host and port are correct")
        print("4. Devices are on the same network")
        return
    
    try:
        # Start plotting in a separate thread
        print("Starting real-time plot...")
        print("Close the plot window to exit")
        
        # Start the plotting
        ani = client.start_plotting()  # This will block until window is closed
        
    except KeyboardInterrupt:
        print("\nShutting down...")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.disconnect()
        print("Disconnected")

if __name__ == "__main__":
    # Install required packages:
    # pip install python-socketio matplotlib numpy
    main()