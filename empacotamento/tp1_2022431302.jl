using JuMP
using Gurobi

mutable struct ProblemData
    n::Int
    pesos::Array{Float64}
end

function readData(file)
    n = 0
    pesos = []
    id_lista = 1
    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int64, q[2])
            pesos = [0.0 for i = 1:n]
        elseif q[1] == "o"
            peso = parse(Float64, q[3])
            pesos[id_lista] = peso
            id_lista += 1
        end
    end
    return ProblemData(n, pesos)
end

file = open(ARGS[1], "r")

data = readData(file)

# Cria o modelo
model = Model(Gurobi.Optimizer)

# xij = 1 se o objeto i for empacotado na caixa j
@variable(model, x[i=1:data.n, j=1:data.n], Bin)

# yi = 1 se a caixa i for usada
@variable(model, y[i=1:data.n], Bin)

# Cada objeto deve ser empacotado em somente uma caixa
for i in 1:data.n
    @constraint(model, sum(x[i, j] for j = 1:data.n) == 1)
end

capacidadeCaixa = 20.0

# A soma dos pesos dos objetos em cada caixa não pode exceder a capacidade da caixa
for j in 1:data.n
    @constraint(model, sum(data.pesos[i] * x[i, j] for i = 1:data.n) <= capacidadeCaixa * y[j])
end

# Função objetivo: minimizar o número de caixas
@objective(model, Min, sum(y[i] for i = 1:data.n))

# Resolve o modelo
optimize!(model)

solucao = round(Int, objective_value(model))

# Exibe os resultados
println("TP1 2022431302 = $solucao")