using JuMP
using HiGHS

mutable struct ProblemData
    n::Int
    vertices::Array{Int}
    arestas::Set{Tuple{Int, Int}}
end

function readData(file)
    n = 0
    vertices = []
    arestas = Set()
    id_lista = 1
    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int64, q[2])
            vertices = [i for i = 1:n]
        elseif q[1] == "e"
            v1 = parse(Float64, q[2])
            v2 = parse(Float64, q[3])
            push!(arestas, (v1, v2))
            id_lista += 1
        end
    end
    return ProblemData(n, vertices, arestas)
end

file = open(ARGS[1], "r")

data = readData(file)

# Cria o modelo
model = Model(HiGHS.Optimizer)

# xij = 1 se o vértice i faz parte da clique
@variable(model, x[i=1:data.n], Bin)

# vértices não conectados não podem estar na mesma clique
for i in 1:data.n
    for j in 1:data.n
        if i != j && !( (i, j) in data.arestas || (j, i) in data.arestas )
            @constraint(model, x[i] + x[j] <= 1)
        end
    end
end

# Função objetivo: maximizar o tamanho da clique
@objective(model, Max, sum(x[i] for i = 1:data.n))

# Resolve o modelo
optimize!(model)

solucao = round(Int, value(sum(x[i] for i = 1:data.n)))

# Exibe os resultados
println("TP1 2022431302 = $solucao")