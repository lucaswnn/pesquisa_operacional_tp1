using JuMP
using HiGHS

mutable struct ProblemData
    n::Int
    custos_producao::Array{Float64}
    demandas::Array{Float64}
    custos_estocagem::Array{Float64}
    multas::Array{Float64}
end

function readData(file)
    n = 0
    custos_producao = []
    demandas = []
    custos_estocagem = []
    multas = []
    id_lista = 1
    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int64, q[2])
            custos_producao = [0 for i = 1:n]
            demandas = [0 for i = 1:n]
            custos_estocagem = [0 for i = 1:n]
            multas = [0 for i = 1:n]
        elseif q[1] == "c"
            t = parse(Int, q[2])
            valor = parse(Float64, q[3])
            custos_producao[t] = valor
            id_lista += 1
        elseif q[1] == "d"
            t = parse(Int, q[2])
            valor = parse(Float64, q[3])
            demandas[t] = valor
            id_lista += 1
        elseif q[1] == "s"
            t = parse(Int, q[2])
            valor = parse(Float64, q[3])
            custos_estocagem[t] = valor
            id_lista += 1
        elseif q[1] == "p"
            t = parse(Int, q[2])
            valor = parse(Float64, q[3])
            multas[t] = valor
            id_lista += 1
        end
    end
    return ProblemData(n, custos_producao, demandas, custos_estocagem, multas)
end

file = open(ARGS[1], "r")

data = readData(file)

# Cria o modelo
model = Model(HiGHS.Optimizer)

# xi: quantidade produzida no período i
@variable(model, x[i=1:data.n] >= 0)

# si: quantidade de produtos armazenados antes do período i
@variable(model, s[i=0:data.n] >= 0)

# ki: quantidade de produtos atrasados antes do período i
@variable(model, k[i=0:data.n] >= 0)

# vértices não conectados não podem estar na mesma clique
for i in 1:data.n
    @constraint(model, s[i-1] + x[i] + k[i] - k[i-1] - data.demandas[i] == s[i])
end

@constraint(model, s[0] == 0)
@constraint(model, s[data.n] == 0)
@constraint(model, k[0] == 0)
@constraint(model, k[data.n] == 0)

# Função objetivo: minimizar o custo
@objective(model,
    Min,
    sum(
        x[i] * data.custos_producao[i] +
        s[i] * data.custos_estocagem[i] +
        k[i] * data.multas[i]
        for i = 1:data.n
    ))

# Resolve o modelo
optimize!(model)

solucao = objective_value(model)

# Exibe os resultados
println("TP1 2022431302 = $solucao")