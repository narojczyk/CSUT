#!/usr/bin/env python

import sys


h_min=float(1e24)
h_max=float(0)
v_min=float(1e24)
v_max=float(0)

file = open(str(sys.argv[1]))
for line in file:
    fields = line.strip().split()
    vol=float(fields[1])
    h11=float(fields[2])
    h22=float(fields[5])
    h33=float(fields[7])
    if vol < v_min:
      v_min=vol

    if vol > v_max:
      v_max=vol

    if h11 < h_min:
      h_min=h11

    if h11 > h_max:
      h_max=h11

    if h22 < h_min:
      h_min=h22

    if h22 > h_max:
      h_max=h22

    if h33 < h_min:
      h_min=h33

    if h33 > h_max:
      h_max=h33

h_int_min=int(h_min*10) - 1
h_int_max=int(h_max*10) + 1

v_int_min=int(v_min/100e0)
v_int_max=int(v_max/100e0) + 1

print("%s=%f" % ("HYmin", float(h_int_min)/10e0))
print("%s=%f" % ("HYmax", float(h_int_max)/10e0))

print("%s=%f" % ("VolYmin", float(v_int_min)*100e0))
print("%s=%f" % ("VolYmax", float(v_int_max)*100e0))

exit()
