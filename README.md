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
Set dynamic/shared library loading path properly. E.g., on Linux (x86_64):
```
export LD_LIBRARY_PATH=/opt/pylon5/lib64
```
Build the package:
```
julia --eval 'using Pkg; pkg"activate ."; pkg"instantiate"; pkg"build"'
```
Run the `pyloncamera.jl` sample:
```
julia --eval 'import Pkg; Pkg.activate("."); include("samples/pyloncamera.jl")'
```
