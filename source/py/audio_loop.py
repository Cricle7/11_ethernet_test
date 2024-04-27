#!/usr/bin/python3.6
from scapy.all import *
import numpy as np

tim = np.array([])
datax = np.array([])
ttemp = 0
bagsize = 100
sample_bag = 1

def pack_callback(packet):
    p = packet

    # 如果UDP包中含有数据层，则把Raw曾的数据提取出来
    if 'Raw' in p:
        data = p.getlayer(Raw)
        for each in data.load:
            tim = np.append(tim, ttemp / (bagsize *sample_bag))
            # datax为数据数组
            datax = np.append(datax, int(each))
            # ttemp为所有数据的个数
            ttemp += 1  # 数据个数
            # bagsize为一组显示单元，控制数组长度，避免数组无限长导致的开销加大
            if ttemp > bagsize:
                self.tim = np.delete(self.tim, [0])
                self.datax = np.delete(self.datax, [0])
                
# while 1:
#     sniff(filter='ip src 192.168.1.11 and udp and udp port 8080', prn=lambda x:x.summary(), count=1)
sniff(filter='udp', prn=pack_callback)