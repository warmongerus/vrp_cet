Tunnel = module("vrp", "lib/Tunnel")
Proxy = module("vrp", "lib/Proxy")

vRPct = {}
vRP = Proxy.getInterface("vRP")
CTserver = Tunnel.getInterface("vrp_cet")
Tunnel.bindInterface("vrp_cet",vRPct)
Proxy.addInterface("vrp_cet",vRPct)

local vagas = {}

local patio = {
    { nome = "Pátio", id_blip = 523, cor = 46, x = 401.414, y = -1648.040, z = 29.292 },
}

function vRPct.setApreendido(v)
    vagas = v
end

-- Function Mensagem
function vRPct.apreendidoSucesso()
    SendNUIMessage({apreendidoSucesso = true})
end

function vRPct.naoPertence()
    SendNUIMessage({naoPertence = true})
end

function vRPct.patioCheio()
    SendNUIMessage({patioCheio = true})
end

function vRPct.valorInvalido()
    SendNUIMessage({valorInvalido = true})
end

function vRPct.naoTemPermissao()
    SendNUIMessage({naoTemPermissao = true})
end

function vRPct.avisoDinheiroInsuficiente()
    SendNUIMessage({avisoDinheiroInsuficiente = true})
end

function vRPct.removidoSucesso()
    SendNUIMessage({removidoSucesso = true})
end

-- Retorna o modelo do carro em que o player está
function vRPct.getModel()
    local ped = GetPlayerPed(-1)
    local currentVehicle = GetVehiclePedIsUsing(ped)
    local model = GetEntityModel(currentVehicle)
    local name = GetDisplayNameFromVehicleModel(model)
    return name
end

-- Checa se o player está em um veiculo
function vRPct.IsInVehicle()
    local ply = GetPlayerPed(-1)
    if IsPedSittingInAnyVehicle(ply) then
      return true
    else
      return false
    end
end

-- Spawna o veiculo com a customização
function vRPct.spawnVeiculo(custom, v)
    -- carrega o modelo do veiculo
    local mhash = GetHashKey(v.modelo)

    local i = 0
    while not HasModelLoaded(mhash) and i < 30000 do
        RequestModel(mhash)
        Citizen.Wait(10)
        i = i+1
    end
    -- spawna o carro
    if HasModelLoaded(mhash) then
        local nveh = CreateVehicle(mhash, vagas[v.slot].x,vagas[v.slot].y,vagas[v.slot].z-1, vagas[v.slot].h, true, false)
        SetVehicleOnGroundProperly(nveh)
        SetVehicleNumberPlateText(nveh, v.placa)
        Citizen.InvokeNative(0xAD738C3085FE7E11, nveh, true, true)
        SetVehicleHasBeenOwnedByPlayer(nveh,true)
        SetModelAsNoLongerNeeded(mhash)
        -- proteção
        FreezeEntityPosition(nveh,true)
        SetVehicleUndriveable(nveh,true)
        SetEntityInvincible(nveh,true)
        -- Coloca a modificação no carro
        if custom and nveh then
            SetVehicleModKit(nveh,0)
            if custom.colour then
                SetVehicleColours(nveh, tonumber(custom.colour.primary), tonumber(custom.colour.secondary))
                SetVehicleExtraColours(nveh, tonumber(custom.colour.pearlescent), tonumber(custom.colour.wheel))
                if custom.colour.neon then
                    SetVehicleNeonLightsColour(nveh,tonumber(custom.colour.neon[1]),tonumber(custom.colour.neon[2]),tonumber(custom.colour.neon[3]))
                end
                if custom.colour.smoke then
                    SetVehicleTyreSmokeColor(nveh,tonumber(custom.colour.smoke[1]),tonumber(custom.colour.smoke[2]),tonumber(custom.colour.smoke[3]))
                end
                if custom.colour.custom then
                    if custom.colour.custom.primary then
                        SetVehicleCustomPrimaryColour(nveh,tonumber(custom.colour.custom.primary[1]),tonumber(custom.colour.custom.primary[2]),tonumber(custom.colour.custom.primary[3]))
                    end
                    if custom.colour.custom.secondary then
                        SetVehicleCustomSecondaryColour(nveh,tonumber(custom.colour.custom.secondary[1]),tonumber(custom.colour.custom.secondary[2]),tonumber(custom.colour.custom.secondary[3]))
                    end
                end
            end

            if custom.plate then
                SetVehicleNumberPlateTextIndex(nveh,tonumber(custom.plate.index))
            end

            SetVehicleWindowTint(nveh,tonumber(custom.mods[46]))
            SetVehicleTyresCanBurst(nveh, tonumber(custom.bulletproof))
            SetVehicleWheelType(nveh, tonumber(custom.wheel))

            ToggleVehicleMod(nveh, 18, tonumber(custom.mods[18]))
            ToggleVehicleMod(nveh, 20, tonumber(custom.mods[20]))
            ToggleVehicleMod(nveh, 22, tonumber(custom.mods[22]))

            if custom.neon then
                SetVehicleNeonLightEnabled(nveh,0, tonumber(custom.neon.left))
                SetVehicleNeonLightEnabled(nveh,1, tonumber(custom.neon.right))
                SetVehicleNeonLightEnabled(nveh,2, tonumber(custom.neon.front))
                SetVehicleNeonLightEnabled(nveh,3, tonumber(custom.neon.back))
            end

            for i,mod in pairs(custom.mods) do
                if i ~= 18 and i ~= 20 and i ~= 22 and i ~= 46 then
                    SetVehicleMod(nveh, tonumber(i), tonumber(mod))
                end
            end

        end
        return true
    end
    return false
end

-- Retira o veiculo
function vRPct.despawnVeiculo()
    local veh = vRP.getNearestVehicle(5000)
    -- deleta o veiculo
    SetVehicleHasBeenOwnedByPlayer(veh,false)
    Citizen.InvokeNative(0xAD738C3085FE7E11, veh, false, true)
    SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(veh))
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(veh))
end

-- Retira o veiculo
function vRPct.despawnAllVeiculo(v)
    -- carrega o modelo do veiculo
    local mhash = GetHashKey(v.modelo)
    -- deleta o veiculo
    SetVehicleHasBeenOwnedByPlayer(mhash,false)
    Citizen.InvokeNative(0xAD738C3085FE7E11, mhash, false, true)
    SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(mhash))
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(mhash))
end

-- Texto 3D
function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

-- Blips
Citizen.CreateThread(function()
    for _, item in pairs(patio) do
        item.blip = AddBlipForCoord(item.x, item.y, item.z)
        SetBlipSprite(item.blip, item.id_blip)
        SetBlipColour(item.blip, item.cor)
        SetBlipAsShortRange(item.blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("~o~Loja~w~ " ..item.nome)
        EndTextCommandSetBlipName(item.blip)
    end
end)

-- Marcações
local entrou = nil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k in pairs(vagas) do
            if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), vagas[k].x, vagas[k].y, vagas[k].z, true ) < 10 then
                if vagas[k].ocupado then
                    DrawText3D(vagas[k].x, vagas[k].y, vagas[k].z, "~y~Apreendido!~w~\nDono: "..vagas[k].dono_nome.."\nModelo: "..vagas[k].modelo.. "\nValor Retirada: ~g~R$"..addComma(vagas[k].valor).."\n~y~/retirar")
                else
                    DrawText3Ds(vagas[k].x, vagas[k].y, vagas[k].z, vagas[k].mensagem)
                end
                if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), vagas[k].x, vagas[k].y, vagas[k].z, true ) < 1 then
                    if vagas[k].ocupado then
                        if type(entrou) == 'nil' and DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId())) then -- se existe um veiculo que o player esta tentando entrar (peguei do vrp_nocarjack)
                            entrou = k
                            CTserver.entrarApreendido(k)
                        end
                    end
                else
                    if entrou == k then
                        entrou = nil
                        CTserver.sairApreendido(k)
                    end
                end
            end
        end
    end
end)

function addComma(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
end