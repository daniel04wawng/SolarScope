import pandas as pd
import numpy as np
from serial import Serial
from datetime import datetime

# Constants for PV system performance
MODULE_EFFICIENCY = 0.18  # PV module efficiency (18%)
INVERTER_EFFICIENCY = 0.95  # Inverter efficiency (95%)

# Set electricity rate (in CAD per kWh, e.g., 0.13 CAD/kWh in Ontario as of 2024)
ELECTRICITY_RATE = 0.13

# Function to read real-time Arduino data
def read_arduino_data(port="/dev/cu.usbmodem1301", baudrate=9600):
    """
    Reads irradiance data from Arduino in real-time.
    Expects data in the format: voltage,irradiance.
    """
    try:
        with Serial(port, baudrate, timeout=1) as ser:
            while True:
                line = ser.readline().decode('utf-8').strip()  # Read and decode
                print(f"Raw Arduino Output: '{line}'")  # Debugging output
                if "," in line:  # Ensure the line contains a comma
                    parts = line.split(",")
                    # Check if the parts can be converted to floats
                    if len(parts) == 2 and all(part.replace('.', '', 1).isdigit() for part in parts):
                        voltage, irradiance = map(float, parts)
                        print(f"Parsed Data: Voltage={voltage} V, Irradiance={irradiance} W/m²")
                        return irradiance  # Return the irradiance value
                    else:
                        print(f"Invalid Data Skipped: '{line}'")
    except Exception as e:
        print(f"Error reading from Arduino: {e}")
        return None

# Function to calculate energy performance
def calculate_energy(building, irradiance, weather):
    """
    Calculate energy output for a building given real-time irradiance
    and weather data adjustments.
    """
    # Update column name for area
    area = building['Footprint']  # Corrected column name
    tilt = building.get('Tilt (degrees)', 0)  # Default tilt to 0 if missing
    orientation = building.get('Orientation', 0)  # Default orientation to 0 if missing

    # Use the correct column for GHI
    if 'GHI' not in weather.columns:
        raise KeyError("No 'GHI' column found in the weather data. Please check the file.")
    ghi = weather['GHI'].mean()  # Average GHI

    # Adjust irradiance for tilt and orientation
    tilt_adjusted_irradiance = irradiance * np.cos(np.radians(tilt))

    # Combine with weather GHI
    effective_irradiance = (tilt_adjusted_irradiance + ghi) / 2

    # Calculate energy output (kWh)
    energy_output = area * effective_irradiance * MODULE_EFFICIENCY * INVERTER_EFFICIENCY
    return energy_output

def calculate_cost_savings(energy_output, electricity_rate):
    # calculate the cost savings in CAD based on energy output and electricity rate.
    return energy_output * electricity_rate

# Main function for dynamic processing
def main():
    # Load novelty building model data
    building_models = pd.read_excel("/Users/tazrinkhalid/Desktop/SolarScope/venv/models_areas.xlsx")
    building_models.columns = building_models.columns.str.strip()  # Strip whitespace
    print("Column Names in Building Models:", building_models.columns.tolist())  # Debugging

    # Load weather data
    weather = pd.read_csv("/Users/tazrinkhalid/Desktop/SolarScope/venv/london_ontario_42.984267_-81.247534_psm3-tmy_60_tmy.csv")

    print("Starting dynamic energy performance calculations...")
    while True:
        # Step 1: Read real-time irradiance from Arduino
        irradiance = read_arduino_data()
        if irradiance is None:
            continue  # Skip iteration if no data is read

        # Step 2: Process each building model dynamically
        for _, building in building_models.iterrows():
            try:
                # Calculate energy output
                energy = calculate_energy(building, irradiance, weather)

                # Calculate cost savings
                cost_savings = calculate_cost_savings(energy, ELECTRICITY_RATE)

                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"{timestamp} | Building: {building['Model Name']} | Energy Output: {energy:.2f} kWh | Cost Savings: ${cost_savings:.2f} CAD")
            except KeyError as e:
                print(f"KeyError: {e}. Please check the column names in models_areas.xlsx.")
                break

        print("Waiting for next irradiance reading...\n")



# Run the main function
if __name__ == "__main__":
    main()
