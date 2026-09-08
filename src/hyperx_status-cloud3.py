import pywinusb.hid as hid
import time
import sys

VID = 0x03F0
PID = 0x05B7
REPORT_ID = 0x66
QUERY_COMMAND = 0x82

result = None


def handler(data):
    global result

    # Response to 66 82 query
    # 66 82 01 ... = connected
    # 66 82 00 ... = disconnected
    if len(data) >= 3:
        if data[0] == REPORT_ID and data[1] == QUERY_COMMAND:
            result = 1 if data[2] == 1 else 0


devices = hid.HidDeviceFilter(
    vendor_id=VID,
    product_id=PID
).get_devices()

target = None

for device in devices:
    if "&col01#" in str(device).lower():
        target = device
        break

if target is None:
    print("0")
    sys.exit(0)

try:
    target.open()
    target.set_raw_data_handler(handler)

    reports = target.find_output_reports()

    for report in reports:
        if report.report_id == REPORT_ID:
            buf = [0] * 62
            buf[0] = REPORT_ID
            buf[1] = QUERY_COMMAND
            report.send(buf)
            break

    
    for _ in range(20):
        if result is not None:
            break
        time.sleep(0.05)

finally:
    try:
        target.close()
    except:
        pass

print("1" if result == 1 else "0")