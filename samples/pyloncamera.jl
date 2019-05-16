using Cameras
using PylonCameras

const images_to_grab = 30

function acquire_images(model_name, serial_number)
    try
        camera = PylonCamera(
            model_name = model_name,
            serial_number = serial_number,
            max_num_buffer = 8,
            grab_result_wait_timeout_ms = 500,
            grab_result_retrieve_timeout_ms = 1)
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
        if isdefined(Main, :camera)
            stop!(camera)
            close!(camera)
        end
    end
end

model_name = length(ARGS) > 0 ? ARGS[1] : nothing
serial_number = length(ARGS) > 1 ? ARGS[2] : nothing

acquire_images(model_name, serial_number)
