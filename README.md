# PylonCameras

Set dynamic/shared library loading path properly. E.g., on Linux (x86_64):
```
export LD_LIBRARY_PATH=/opt/pylon5/lib64
```
Build the package:
```
julia --eval 'using Pkg; pkg"activate ."; pkg"instantiate"; pkg"build"'
```
