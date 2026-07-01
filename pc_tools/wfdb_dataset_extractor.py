import wfdb
import numpy as np
import os

# CONFIGURATION PARAMETERS
DATABASE_NAME = 'mitdb'           # PhysioNet database directory
RECORD_NAME   = '100'             # Specific record to download
CHANNEL_INDEX = 0                 # Channel to extract
NUM_SAMPLES   = 1024              # Number of samples

DAC_BIT_DEPTH = 8                 # Resolution of the target DAC (e.g., 8-bit or 12-bit)
OUTPUT_FILE   = 'dataset.txt'     # Output filename for BRAM initialization

def extract_and_format_dataset():
    """
    Main function to download, process, and save the dataset.
    """
    print(f"1. Downloading {NUM_SAMPLES} samples from PhysioNet ({DATABASE_NAME}/{RECORD_NAME})...")
    
    try:
        # Fetch the specific segment from PhysioNet servers
        record, fields = wfdb.rdsamp(RECORD_NAME, pn_dir=DATABASE_NAME, sampto=NUM_SAMPLES, channels=[CHANNEL_INDEX])
        
        # Extract the raw 1D array for the selected channel
        raw_signal = record[:, 0]
    except Exception as e:
        print(f"Error downloading dataset: {e}")
        return

    print(f"2. Normalizing data for a {DAC_BIT_DEPTH}-bit DAC...")
    
    # Find minimum and maximum values for Min-Max scaling
    sig_min = np.min(raw_signal)
    sig_max = np.max(raw_signal)
    
    # Calculate the maximum integer value for the given DAC bit depth
    # 8-bit -> 255
    max_dac_value = (1 << DAC_BIT_DEPTH) - 1 
    
    # Apply Min-Max Scaling: (X - Xmin) / (Xmax - Xmin) * TargetMax
    normalized = ((raw_signal - sig_min) / (sig_max - sig_min)) * max_dac_value
    
    # Convert floats to integers and strictly enforce bounds (0 to max_dac_value)
    normalized = np.clip(normalized, 0, max_dac_value).astype(int)

    print(f"3. Generating hexadecimal BRAM initialization file '{OUTPUT_FILE}'...")
    
    # Calculate how many hex characters are needed (8-bit -> 2 chars)
    hex_width = (DAC_BIT_DEPTH + 3) // 4
    
    export_path = f"fpga_vDAC/build/{OUTPUT_FILE}"
    os.makedirs(os.path.dirname(export_path), exist_ok=True)
    
    with open(export_path, 'w') as f:
        for val in normalized:
            # Write each value formatted as uppercase hexadecimal, padded with leading zeros
            f.write(f"{val:0{hex_width}X}\n")

    print(f"Success! {len(normalized)} data points saved to '{OUTPUT_FILE}'.")

if __name__ == "__main__":
    extract_and_format_dataset()