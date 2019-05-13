using Cameras
using PylonCameras

const images_to_grab = 30

function acquire_images()
    camera = PylonCamera(
        max_num_buffer = 8,
        grab_result_wait_timeout_ms = 100,
        grab_result_retrieve_timeout_ms = 1)
    try
        println("Using $(PylonCameras.info(camera))")
        open!(camera)
        start!(camera, images_to_grab)

        while isrunning(camera)
            img = take!(camera)
            print("ID $(id(img)), No. $(image_number(img)) @ $(timestamp(img)), size $(size(img)) : ")
            @show img[1,1,1]
            release!(img)
        end
    catch e
        println(e)
    finally
        stop!(camera)
        close!(camera)
    end
end

acquire_images()
