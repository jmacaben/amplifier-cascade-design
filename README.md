# Voltage Amplifier Cascade Designer (MATLAB)

## Overview

This project models and optimizes cascaded voltage amplifier systems under realistic (non-ideal) conditions.

Given:

* A set of amplifier blocks (with input/output resistances and gain)
* A source with internal resistance
* A load resistance
* Design constraints (minimum signal level, required load power)

The script searches all possible amplifier sequences (up to 3 stages) and determines:

* The optimal cascade configuration
* The best input tuning resistor ($R_X$)
* The resulting output voltage and delivered power

---

## Example Output

```
CAB | RX=1.23e+06 ohm | Vout=8.54 V | PL=0.2920 W | error=0.0080
```

---

## Future Improvements

* Support for current, transresistance, and transconductance amplifiers


