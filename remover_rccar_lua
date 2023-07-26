local sampev = require('samp.events')

function main()
    while not isSampAvailable() do wait(500) end
    while true do
        wait(0)
        for id, vehicle in pairs(getAllVehicles()) do
            local modelId = getCarModel(vehicle)
            local cX, cY, cZ = getCarCoordinates(vehicle)
            if (modelId == 441 or modelId == 564) and getDistanceBetweenCoords3d(cX, cY, cZ, 1383.6761474609, -1756.1390380859, 13.546875) < 60 then
                deleteCar(vehicle)
            end
        end
    end
end
