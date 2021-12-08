using PylonCameras
using Test

@testset "pylon_camera_tests" begin
    ENV["PYLON_CAMEMU"] = 1

    camera = PylonCamera()

    @testset "info" begin
        expected_vendor_name = "Basler"
        expected_model_name = "Emulation"
        expected_serial_number(n::Int) = "0815-$(lpad(string(n), 4, '0'))"

        vendor_name, model_name, serial_number = PylonCameras.info(camera)

        @test vendor_name == expected_vendor_name
        @test model_name == expected_model_name
        @test serial_number == expected_serial_number(0)
    end
end
