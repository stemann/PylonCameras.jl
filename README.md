# PylonCameras

## Docker
Build the image:
```
docker build -t pylon_cameras .
```

Start interactive Julia session with PylonCameras activated:
```
docker run --rm -it pylon_cameras
```

Run the `pyloncamera.jl` sample - passing through USB device 2 on bus 4:
```
docker run --rm -it --device=/dev/bus/usb/004/002 pylon_cameras julia --eval 'import Pkg; Pkg.activate("."); include("samples/pyloncamera.jl")'
```

## Local
Ensure the dynamic/shared library loading path includes the proper version of Basler pylon (see required major and minor version in `Dockerfile`). E.g., on Linux (x86_64):
```
export LD_LIBRARY_PATH=/opt/pylon5/lib64
```
On macOS:
```
export LD_LIBRARY_PATH=/Library/Frameworks/pylon.framework/Libraries
```
Build the package:
```
julia --eval 'using Pkg; pkg"activate ."; pkg"instantiate"; pkg"build"'
```
Run the `pyloncamera.jl` sample:
```
julia --eval 'import Pkg; Pkg.activate("."); include("samples/pyloncamera.jl")'
```
Set `PYLON_CAMEMU=N` to enable the emulation of `N` cameras.

Optionally, use args to specify which camera model and serial number to use:
```
PYLON_CAMEMU=2 julia --eval 'import Pkg; Pkg.activate("."); include("samples/pyloncamera.jl")' Emulation 0815-0001
```
