local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local cfg = module("vrp_cet", "cfg/config")

vRPct = {}
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
CTclient = Tunnel.getInterface("vrp_cet")
GNclient = Tunnel.getInterface("vrp_adv_garages")
Tunnel.bindInterface("vrp_cet",vRPct)
Proxy.addInterface("vrp_cet",vRPct)

-- vRP
vRP._prepare("sRP/cet",[[
    CREATE TABLE IF NOT EXISTS vrp_cet(
        id INTEGER AUTO_INCREMENT,
        dono INTEGER,
        dono_nome VARCHAR(255),
        modelo VARCHAR(255),
        placa VARCHAR(20),
        valor INTEGER,
        slot INTEGER,
        CONSTRAINT pk_cet PRIMARY KEY(id)
    )
]])

vRP._prepare("sRP/inserir_apreensao","INSERT INTO vrp_cet(dono, dono_nome, modelo, placa, valor, slot) VALUES(@dono, @dono_nome, @modelo, @placa, @valor, @slot)")
vRP._prepare("sRP/get_apreendidos","SELECT * FROM vrp_cet")
vRP._prepare("sRP/remover_apreensao","DELETE FROM vrp_cet WHERE slot = @slot")

async(function()
    vRP.execute("sRP/cet")
    vRPct.carregarApreendidos()
end)

local vagas = cfg.vagas

local retirar = {}

function updateTable(t1, t2)
    for k,v in pairs(t2) do
      t1[k] = v
    end
end

function vagaVazia()
    for k,v in pairs(vagas) do
        if not v.ocupado then
            return k
        end
    end
    return nil
end

function vRPct.carregarApreendidos()
    local Svagas = vRP.query('sRP/get_apreendidos')
    for k,v in pairs(Svagas) do
        vagas[v.slot].ocupado = true
        updateTable(vagas[v.slot], v)
    end
end

function vRPct.entrarApreendido(k)
    retirar[source] = k
end

function vRPct.sairApreendido(k)
    retirar[source] = nil
end

function vRPct.spawnarCarro(user_id, veiculo)
    local source = vRP.getUserSource(user_id)
    local data = vRP.getSData("custom:u"..veiculo.dono.."veh_"..veiculo.modelo)
    local custom = json.decode(data)
    CTclient.spawnVeiculo(source, custom, veiculo)
end

function vRPct.despawnarCarro(user_id, veiculo)
    local source = vRP.getUserSource(user_id)
    CTclient.despawnAllVeiculo(source, veiculo)
end

AddEventHandler('chatMessage', function(source, name, msg)
    sm = stringsplit(msg, " ");
    args = sm[2]
    if sm[1] == "/apreender" then
        local k = vagaVazia()
        if type(k) ~= 'nil' then
            local user_id = vRP.getUserId(source)
            if vRP.hasPermission(user_id, cfg.perm) then
                if args then
                    local user_id = vRP.getUserByRegistration(args)
                    local identity = vRP.getUserIdentity(user_id)
                    local ok, vtype, model = GNclient.getNearestOwnedVehicle(vRP.getUserSource(user_id),50000)
                    if ok then
                        local amount = vRP.prompt(source, "Valor que você quer colocar para retirar do patio","")
                        local amount = parseInt(amount)
                        if amount > 0 then
                            local veiculo = {
                                dono = user_id,
                                dono_nome = identity.name .. " " ..identity.firstname,
                                telefone = identity.phone,
                                modelo = model,
                                valor = amount,
                                slot = k,
                                placa = identity.registration
                            }
                            vRP.execute("sRP/inserir_apreensao", veiculo)
                            vagas[k].ocupado = true
                            updateTable(vagas[k], veiculo)
                            for uid,src in pairs(vRP.getUsers()) do
                                CTclient.setApreendido(src, vagas)
                            end
                            local carros = json.decode(vRP.getSData("apreendido:u"..user_id))
                            if not carros then carros = {} end
                            carros[model] = true
                            vRP.setSData("apreendido:u"..user_id, json.encode(carros))
                            CTclient.despawnVeiculo(source)
                            vRPct.spawnarCarro(user_id, veiculo)
                            vRPct.despawnarCarro(user_id, veiculo)
                            CTclient.apreendidoSucesso(source)
                        else
                            CTclient.valorInvalido(source)
                        end
                    else
                        vRPclient._notify(source,"Não existe nenhum veiculo proximo")
                    end
                end
            else
                CTclient.naoTemPermissao(source)
            end
        else
            CTclient.patioCheio(source)
        end
        CancelEvent()
    end

    if type(retirar[source]) ~= 'nil' then
        if sm[1] == "/retirar" then
            local k = retirar[source]
            local nuser_id = vRP.getUserId(source)
            local id_dono = vagas[k].dono
            local modelo_db = vagas[k].modelo
            local valor = vagas[k].valor
            if nuser_id == id_dono then
                if vRP.tryPayment(nuser_id, valor) then
                    vRP.execute("sRP/remover_apreensao", {slot = k})
                    vagas[k].ocupado = false
                    for uid,src in pairs(vRP.getUsers()) do
                        CTclient.setApreendido(src, vagas)
                    end
                    CTclient.despawnVeiculo(source)
                    CTclient.removidoSucesso(source)
                    local apreendido = json.decode(vRP.getSData("apreendido:u"..id_dono))
                    apreendido[string.lower(modelo_db)] = nil
                    vRP.setSData("apreendido:u"..id_dono, json.encode(apreendido))
                else
                    CTclient.avisoDinheiroInsuficiente(source)
                end
            else
                CTclient.naoPertence(source)
            end
            CancelEvent()
        end
    end
end)

local spawn_veh = false
AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
    if user_id then
        spawn_veh = true
        for uid,src in pairs(vRP.getUsers()) do
            CTclient.setApreendido(src, vagas)
        end
        if spawn_veh then
            for k,v in pairs(vagas) do
                if v.ocupado then
                    vRPct.despawnarCarro(user_id, v)
                    SetTimeout(1000, function()
                        vRPct.spawnarCarro(user_id, v)
                    end)
                end
            end
        end
    end
end)

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end