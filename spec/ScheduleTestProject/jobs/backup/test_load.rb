$Ot.currentVariant = 'Load'

sc = OtSkimCube.new
mat = OtMatrix.new(2)
timePeriods = [10050]

timePeriods.each { |t|
  mat[] = 0
  mat[1,2] = 10
  sc[1,30,t,1,1,1] = mat
}

transit = OtTransit.new
transit.loadMatricesFromSkimCube  = true
transit.odMatrix                  = [1,30,timePeriods,1,1,1]
transit.load                      = [1,30,10,1,1,1]
transit.network                   = [30,10]

# schedule based properties
transit.scheduleDurations = [5]
transit.scheduleStartTime = timePeriods.first
#transit.schedulePathFactors = [[1.25, 0.0], [1.25, 0.0], [1.0,1.0]] # [cost[alpha,beta], time, connections]

# schedule based flags
transit.scheduleBased = true
transit.dyrtBasedSchedule = false
transit.scheduleAnimateLoads = true
# transit.clearCandidateLinks = false


# Candidate finding
#transit.searchRadius = [['Walk'.to_mode, 2]]
#transit.minFind      = [['Walk'.to_mode, 1]]


# Properties to clean up
#transit.minProbability = [0.01, 0.0]
#transit.logitParameters  = [0.1, 0.1]

transit.execute
