import ctypes
import win32api
import win32con
import pywintypes
import sys
import os

def set_res(width, height, hz):
    devmode = win32api.EnumDisplaySettings(None, win32con.ENUM_CURRENT_SETTINGS)
    devmode.PelsWidth = width
    devmode.PelsHeight = height
    devmode.DisplayFrequency = hz
    devmode.Fields = win32con.DM_PELSWIDTH | win32con.DM_PELSHEIGHT | win32con.DM_DISPLAYFREQUENCY
    
    # CDS_UPDATEREGISTRY ayarları kalıcı yapar, 0 sadece oturum boyu değiştirir
    win32api.ChangeDisplaySettings(devmode, 0)

def toggle():
    # Mevcut ayarları al
    current = win32api.EnumDisplaySettings(None, win32con.ENUM_CURRENT_SETTINGS)
    curr_w = current.PelsWidth
    
    try:
        if curr_w == 2560:
            # 2560 ise 1024'e geç
            set_res(1024, 768, 165)
        else:
            # Diğer her durumda (zaten 1024 ise veya farklıysa) 2560'a dön
            set_res(2560, 1440, 165)
    except Exception:
        pass # Hata olsa bile kullanıcıya konsol göstermemek için sessizce geç

if __name__ == "__main__":
    toggle()