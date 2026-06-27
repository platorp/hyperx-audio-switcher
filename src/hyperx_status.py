"""
hyperx_status.py
Queries the HyperX Cloud III S Wireless USB dongle via HID to detect
whether the headset is currently connected to the dongle.

Returns:
    "1" — headset is connected (powered on and paired)
    "0" — headset is disconnected (powered off or out of range)

Discovery method:
    USB traffic was captured with USBPcap/Wireshark while HyperX NGENUITY
    was open. The dongle exposes a HID interface on usage page 0x1C0 with
    report IDs 12 (0x0C) and 13 (0x0D). Sending report ID 12 with the
    query bytes [0x0C, 0x02, 0x03, 0x01, 0x00, 0x02, ...] causes the dongle
    to respond with byte[6] = 2 when the headset is connected, and 0 when not.
"""

import pywinusb.hid as hid
import sys
import time

VENDOR_ID   = 0x03F0  # HP, Inc (HyperX)
PRODUCT_ID  = 0x06BE  # HyperX Cloud III S Wireless dongle
USAGE_PAGE  = 0x1C0   # Vendor-defined interface carrying connection status
REPORT_ID   = 12      # 0x0C — status query report
CONNECTED   = 2       # byte[6] value when headset is on and connected

result = [None]


def handler(data):
    """Callback fired when the device sends an input report."""
    if data[0] == REPORT_ID and result[0] is None:
        result[0] = data[6]


def main():
    all_devices = hid.HidDeviceFilter(
        vendor_id=VENDOR_ID, product_id=PRODUCT_ID
    ).get_devices()

    if not all_devices:
        print("0")  # Dongle not found at all
        sys.exit(0)

    for device in all_devices:
        try:
            device.open()
            caps = device.hid_caps

            if caps.usage_page == USAGE_PAGE:
                device.set_raw_data_handler(handler)
                out_reports = device.find_output_reports()

                for r in out_reports:
                    if r.report_id == REPORT_ID:
                        buf = [0x00] * 64
                        buf[0] = REPORT_ID
                        buf[1] = 0x02
                        buf[2] = 0x03
                        buf[3] = 0x01
                        buf[4] = 0x00
                        buf[5] = 0x02
                        r.send(buf)

                time.sleep(1)

            device.close()

        except Exception:
            try:
                device.close()
            except Exception:
                pass

    print("1" if result[0] is not None and result[0] >= CONNECTED else "0")


if __name__ == "__main__":
    main()
