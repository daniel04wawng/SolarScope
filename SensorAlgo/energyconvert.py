import pandas as pd
import numpy as np
from serial import Serial
from datetime import datetime

# Constants for PV system performance
MODULE_EFFICIENCY = 0.18  # PV module efficiency (18%)
INVERTER_EFFICIENCY = 0.95  # Inverter efficiency (95%)
ELECTRICITY_RATE = 0.13  # CAD per kWh

# Shared data structure
latest_results = {
    "timestamp": None,
    "building": None,
    "energy_output": None,
    "cost_savings": None
}

def read_arduino_data(port="/dev/cu.usbmodem11301", baudrate=9600):
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

def calculate_energy(building, irradiance, weather):
    area = building['Footprint']
    tilt = building.get('Tilt (degrees)', 0)
    ghi = weather['GHI'].mean()
    tilt_adjusted_irradiance = irradiance * np.cos(np.radians(tilt))
    effective_irradiance = (tilt_adjusted_irradiance + ghi) / 2
    energy_output = area * effective_irradiance * MODULE_EFFICIENCY * INVERTER_EFFICIENCY
    return energy_output

def calculate_cost_savings(energy_output):
    return energy_output * ELECTRICITY_RATE

def data_processing_thread():
    global latest_results
    building_models = pd.read_excel("/Users/tazrinkhalid/SS/SolarScope/SensorAlgo/models_areas.xlsx")
    building_models.columns = building_models.columns.str.strip()
    weather = pd.read_csv("/Users/tazrinkhalid/SS/SolarScope/SensorAlgo/london_ontario_42.984267_-81.247534_psm3-tmy_60_tmy.csv")

    print("Starting data processing thread...")
    while True:
        irradiance = read_arduino_data()
        if irradiance is None:
            continue
        for _, building in building_models.iterrows():
            try:
                energy = calculate_energy(building, irradiance, weather)
                cost_savings = calculate_cost_savings(energy)
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                latest_results = {
                    "timestamp": timestamp,
                    "building": building['Model Name'],
                    "energy_output": round(energy, 2),
                    "cost_savings": round(cost_savings, 2)
                }
                output_string = (
                    f"{timestamp} | Building: {building['Model Name']} | "
                    f"Energy Output: {energy:.2f} kWh | Cost Savings: ${cost_savings:.2f} CAD"
                )
                print(output_string)

                # Write to a file (overwrites each time)
                with open("output.txt", "w") as file:
                    file.write(output_string + "\n")

            except KeyError as e:
                print(f"KeyError: {e}. Please check the column names in models_areas.xlsx.")

data_processing_thread()
