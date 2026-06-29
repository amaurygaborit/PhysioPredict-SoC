import serial
import time

PORT = 'COM5'
BAUD_RATE = 115200

def main():
    print(f"Opening port {PORT} at {BAUD_RATE} baud...")
    try:
        ser = serial.Serial(PORT, BAUD_RATE)
        print("Connection successful! Waiting for FPGA data...\n")
        
        while True:
            # Read exactly 1 byte from FPGA
            raw_data = ser.read(1)
            
            # Convert binary byte to integer (0-255)
            value = int.from_bytes(raw_data, byteorder='big')
            
            print(f"Value received: {value:3d}")
            
    except serial.SerialException as e:
        print(f"Serial port error: {e}")
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()

if __name__ == "__main__":
    main()