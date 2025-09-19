using JuMP
using Gurobi

mutable struct ProblemData
    n::Int
    arestas::Set{Tuple{Int,Int}}
end

function readData(file)
    n = 0
    arestas = Set()
    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int64, q[2])
        elseif q[1] == "e"
            v1 = parse(Float64, q[2])
            v2 = parse(Float64, q[3])
            push!(arestas, (v1, v2))
        end
    end
    return ProblemData(n, arestas)
end

file = open(ARGS[1], "r")

data = readData(file)

# Cria o modelo
model = Model(Gurobi.Optimizer)
set_attribute(model, "OutputFlag", 0)

# xij = 1 se o vértice i recebe a cor j
@variable(model, x[i=1:data.n, j=1:data.n], Bin)

# yi = 1 se a cor i é usada
@variable(model, y[i=1:data.n], Bin)

# vértices só podem ter uma cor
for i in 1:data.n
    @constraint(model, sum(x[i, j] for j = 1:data.n) == 1)
end

# vértices conectados não podem ter a mesma cor
for k in 1:data.n
    for (u, v) in data.arestas
        @constraint(model, x[u, k] + x[v, k] <= y[k])
    end
end

# Função objetivo: minimizar o número de cores usadas
@objective(model, Min, sum(y[i] for i = 1:data.n))

# Resolve o modelo
optimize!(model)

solucao = round(Int, objective_value(model))

# Exibe os resultados
println("TP1 2022431302 = $solucao")