include(joinpath("..", "src", "PylonCameras.jl"))

using Cameras
using ResourcePools

const images_to_grab = 30
const max_num_buffer = 8
const grab_result_wait_timeout_ms = 100
const grab_result_retrieve_timeout_ms = 1

camera = PylonCameras.PylonCamera(max_num_buffer, grab_result_wait_timeout_ms, grab_result_retrieve_timeout_ms)
try
    println("Using $(PylonCameras.info(camera))")
    start!(camera, images_to_grab)

    while isrunning(camera)
        img = take!(camera)
        print("$(size(img)) : ")
        @show img[1,1,1]
        release!(img)
    end
catch e
    println(e)
finally
    stop!(camera)
    PylonCameras.close!(camera)
end
