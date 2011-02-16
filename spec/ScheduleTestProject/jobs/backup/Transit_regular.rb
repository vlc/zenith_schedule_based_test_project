sc = OtSkimCube.new
mat = OtMatrix.new(2)
mat[] = 0
mat[1,2] = 10
sc[1,30,10,1,1,1] = mat

transit = OtTransit.new

transit.loadMatricesFromSkimCube = true
transit.load = [1,30,10,1,1,1]

pmturi = [1,1,1,1,1,1]
transit.initialLoad = [[40, pmturi]]
transit.capacityFactor = [[40, 1.0]]
transit.scale = [0.3]
transit.minProbability = [0.1, 0.1, 0.1]

transit.selectedCentroids = [[1,0]]

transit.execute
