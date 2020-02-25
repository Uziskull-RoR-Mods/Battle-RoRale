@echo off
for /R %%f in (*.png) do python img2map.py "%%~nxf"