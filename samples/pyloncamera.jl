using Pkg
Pkg.activate(".")

include(joinpath("..", "src", "PylonCameras.jl"))
using Cameras

const images_to_grab = 10
const grab_result_wait_timeout_ms = 100
const grab_result_retrieve_timeout_ms = 1

camera = PylonCameras.PylonCamera(grab_result_wait_timeout_ms, grab_result_retrieve_timeout_ms)
println("Using $(PylonCameras.info(camera))")
start!(camera, images_to_grab)

while isrunning(camera)
    grab_result, img = take!(camera)
    print("$(size(img)) : ")
    @show img[1,1]
    PylonCameras.release!(grab_result)
end
