using JuMP
using Gurobi

mutable struct ProblemData
    n::Int
    arestas::Set{Tuple{Int,Int}}
    arestas_aux::Set{Tuple{Int,Int}}
end

function readData(file)
    n = 0
    arestas = Set()
    arestas_aux = Set()
    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int64, q[2])
        elseif q[1] == "e"
            v1 = parse(Float64, q[2])
            v2 = parse(Float64, q[3])
            push!(arestas, (v1, v2))
            push!(arestas_aux, (v1, v2))
            push!(arestas_aux, (v2, v1))
        end
    end
    return ProblemData(n, arestas, arestas_aux)
end

file = open(ARGS[1], "r")

data = readData(file)

# Cria o modelo
model = Model(Gurobi.Optimizer)
set_attribute(model, "OutputFlag", 0)

# xic = 1 se o vértice i recebe a cor c
@variable(model, x[i=1:data.n, c=1:data.n], Bin)

# yc = 1 se a cor c é usada
@variable(model, y[c=1:data.n], Bin)

# zc1c2 = 1 se os vértices com a cor c1 tem vizinho com a cor c2
@variable(model, z[c1=1:data.n, c2=1:data.n], Bin)

@variable(model, t[(u, v) in data.arestas_aux, c1=1:data.n, c2=1:data.n], Bin)

# vértices só podem ter uma cor
for v in 1:data.n
    @constraint(model, sum(x[v, c] for c = 1:data.n) == 1)
end

# vértices conectados não podem ter a mesma cor
for c in 1:data.n
    for (u, v) in data.arestas
        @constraint(model, x[u, c] + x[v, c] <= y[c])
    end
end

# y[(u,v), c1, c2] = x[u,c1] * x[v,c2]
for c1 in 1:data.n
    for c2 in 1:data.n
        if c1 != c2
            for (u, v) in data.arestas_aux
                @constraint(model, t[(u, v), c1, c2] <= x[u, c1])
                @constraint(model, t[(u, v), c1, c2] <= x[v, c2])
                @constraint(model, t[(u, v), c1, c2] >= x[u, c1] + x[v, c2] - 1)
            end
        end
    end
end

# se vértices ligados tem cores diferentes, z[c1,c2] = 1
for c1 in 1:data.n
    for c2 in 1:data.n
        if c1 != c2
            for (u, v) in data.arestas_aux
                @constraint(model, z[c1, c2] >= t[(u, v), c1, c2])
                @constraint(model, z[c2, c1] >= t[(u, v), c2, c1])
            end
        end
    end
end

# se não existe ligação entre vértices com cores c1 e c2, z[c1,c2] = 0
for c1 in 1:data.n
    for c2 in 1:data.n
        if c1 != c2
            @constraint(model, z[c1, c2] <= sum(t[(u, v), c1, c2] for (u, v) in data.arestas_aux))
            @constraint(model, z[c2, c1] <= sum(t[(u, v), c2, c1] for (u, v) in data.arestas_aux))
        end
    end
end

for c1 in 1:data.n
    for c2 in 1:data.n
        if c1 != c2
            @constraint(model, z[c1, c2] >= y[c1] + y[c2] - 1)
        end
    end
end

# Função objetivo: maximizar o número de cores usadas
@objective(model, Max, sum(y[i] for i = 1:data.n))

# Resolve o modelo
optimize!(model)

solucao = round(Int, objective_value(model))

# Exibe os resultados
println("TP1 2022431302 = $solucao")