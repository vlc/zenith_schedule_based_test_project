require 'Utils/TestAssistant'

class TC_load < OtTestCase

  def setup
    clearOutputTables
    @tr = OtTransit.new
    @timePeriods = [10050]
    @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], 2, [[1,2,10]]) }
    @tr.loadMatricesFromSkimCube = true
    @tr.odMatrix = [1,30,@timePeriods,1,1,1]
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    @tr = nil
    super
  end

  def test_simple
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      #@tr.scheduleDepartureFractions = [1.0, 0.0, 0.0]
      #@tr.schedulePathFactors = [[1.25, 0.0], [1.25, 0.0], [1.0,1.0]] # [cost[alpha,beta], time, connections]

      # EXECUTE!!
      @tr.execute

      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',10050,1,1,1,1,0], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'PT',10060,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [6,1,'PT',10066,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',10070,1,1,1,2,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [4,1,'PT',10076,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Walk',10090,1,1,1,2,0], "load"), "walk egress")

      # transit line table
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers

      assert_in_delta(6, 				@db.get_value('link5_2data1', [1,1,'Walk',10050,1,1,1,1,0], 'cost'), TEST_DELTA, "walk access cost")
      assert_in_delta(30.0 / 4, @db.get_value('link5_2data1', [2,1,'PT',10060,1,1,1,1,1],   'cost'), TEST_DELTA, "pt leg cost")
      assert_in_delta(30.0 / 4, @db.get_value('link5_2data1', [6,1,'PT',10066,1,1,1,1,1],   'cost'), TEST_DELTA, "pt leg cost")
      assert_in_delta(30.0 / 4, @db.get_value('link5_2data1', [7,1,'PT',10070,1,1,1,2,1],   'cost'), TEST_DELTA, "pt leg cost")
      assert_in_delta(30.0 / 4, @db.get_value('link5_2data1', [4,1,'PT',10076,1,1,1,1,1],   'cost'), TEST_DELTA, "pt leg cost")
      assert_in_delta(6, 				@db.get_value('link5_2data1', [5,1,'Walk',10090,1,1,1,2,0], 'cost'), TEST_DELTA, "walk egress cost")
    }

  end

  def test_animateLoads
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      #@tr.scheduleDepartureFractions = [1.0, 0.0, 0.0]
      #@tr.schedulePathFactors = [[1.25, 0.0], [1.25, 0.0], [1.0,1.0]] # [cost[alpha,beta], time, connections]

      @tr.scheduleAnimateLoads = true
      # @tr.scheduleAggregateTimePeriods = { 10000..10070 => 2, 10071..10090 => 3 }.to_a

      # EXECUTE!!
      @tr.execute

      # Note that the walk legs are 7 minutes long because they take 6 min in total so will be from [s, s+6] which spans 7 actual minute slices
      (0..6).each  { |off| assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',10050+off,1,1,1,1,0], "load"), "walk access") } # 7 min
      (0..4).each  { |off| assert_equal(10, @db.get_value('link5_2data1', [2,1,'PT',  10060+off,1,1,1,1,1], "load"), "walk access") } # 5 min
      # 1 min dwell time
      (0..3).each  { |off| assert_equal(10, @db.get_value('link5_2data1', [6,1,'PT',  10066+off,1,1,1,1,1], "load"), "walk access") } # 4 min
      (0..4).each  { |off| assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',  10070+off,1,1,1,2,1], "load"), "walk access") } # 5 min
      # 1 min dwell time
      (0..13).each { |off| assert_equal(10, @db.get_value('link5_2data1', [4,1,'PT',  10076+off,1,1,1,1,1], "load"), "walk access") } # 14 min
      (0..6).each  { |off| assert_equal(10, @db.get_value('link5_2data1', [5,1,'Walk',10090+off,1,1,1,2,0], "load"), "walk egress") } # 7 min

      assert_equal(42*10, OtQuery.execute_to_a("SELECT sum(load) FROM link5_2data1").flatten.first, "total load")

      # assert_equal(0, OtQuery.execute_to_a("SELECT count(*) FROM 'transitline5data1'"), "transitline table should be empty")
      # transit line table
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers
    }

  end

  def test_aggregateLoads
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      # @tr.scheduleAnimateLoads = true
      @tr.logitParameters  = [0.1]

      # EXECUTE!!
      @tr.scheduleAggregateTimePeriods = { 10000..10069 => 2, 10070..10090 => 3 }.to_a
      @tr.execute

      #                                                           |- Time Period
      #                                                           v
      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk', 2,1,1,1,1,0], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'PT',   2,1,1,1,1,1], "load"), "walk access")

      assert_equal(10, @db.get_value('link5_2data1', [6,1,'PT',   2,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',   3,1,1,1,2,1], "load"), "walk access")

      assert_equal(10, @db.get_value('link5_2data1', [4,1,'PT',   3,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Walk', 3,1,1,1,2,0], "load"), "walk egress")

      # if we change the aggregation to include 10070 in time period 2, the start of link 7 will move to time period 2 from 3
      @tr.scheduleAggregateTimePeriods = { 10000..10070 => 2, 10071..10090 => 3 }.to_a
      @tr.execute
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',   2,1,1,1,2,1], "load"), "walk access")

      # transit line table
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT',2,1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT',2,1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT',2,1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers

      # if we change the aggregation such that the first half of transit line isn't aggregated, then:
      # -> there should be no link load on links starting outside the period of interest AND
      # -> transit line table should use the time period of the last link instead
      @tr.scheduleAggregateTimePeriods = { 10071..10090 => 3 }.to_a
      @tr.execute

      assert_raises(RuntimeError) { @db.get_value('link5_2data1', [1,1,'Walk',10050,1,1,1,1,0], "load") }

      #                                                             |- Note that time period has changed from 2 -> 3
      #                                                             v
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT',3,1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT',3,1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT',3,1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers
    }

  end

  def test_aggregateAndAnimate
    assert_nothing_raised(RuntimeError) {
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAnimateLoads = true
      @tr.scheduleAggregateTimePeriods = { 10000..10069 => 2, 10070..10090 => 3 }.to_a
      @tr.execute

      # aggregate should trump animate!
      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk', 2,1,1,1,1,0], "load"), "walk access")
		}
	end

  def test_multiple_od_matrices
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @timePeriods = [10050,10052]
      @timePeriods.zip([10.0, 4.5]).each { |t, value| create_matrix([1,30,t,1,1,1], 2, [[1,2,value]]) }
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [[5],[5]]
      @tr.odMatrix = [1,30,@timePeriods,1,1,1]


      # EXECUTE!!
      @tr.scheduleAggregateTimePeriods = { 10000..10090 => 2 }.to_a
      @tr.execute

      assert_equal(14.5, @db.get_value('link5_2data1', [1,1,'Walk', 2,1,1,1,1,0], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [2,1,'PT',   2,1,1,1,1,1], "load"), "walk access")

      assert_equal(14.5, @db.get_value('link5_2data1', [6,1,'PT',   2,1,1,1,1,1], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [7,1,'PT',   2,1,1,1,2,1], "load"), "walk access")

      assert_equal(14.5, @db.get_value('link5_2data1', [4,1,'PT',   2,1,1,1,1,1], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [5,1,'Walk', 2,1,1,1,2,0], "load"), "walk egress")

    }

  end

  def test_multiple_classes
    assert_nothing_raised(RuntimeError) {

      # create matrices
      walk,car,pt = ['Walk', 'Vehicle', 'PT'].to_mode
      wawe_7_8, wawe_8_9 = [1,pt,7,11,1,1], [1,pt,8,11,1,1]
      wace_7_8, wace_8_9 = [1,pt,7,12,1,1], [1,pt,8,12,1,1]
      [wawe_7_8, wawe_8_9, wace_7_8, wace_8_9].each { |pmturi| create_matrix(pmturi, 2, [[1,2,1.0]]) }

      # schedule based properties
      @timePeriods = [10050,10052]
      @tr.scheduleStartTime = @timePeriods
      @tr.modes    = [[walk,walk], [walk,car]]
      @tr.odMatrix = [[wawe_7_8, wawe_8_9], [wace_7_8, wace_8_9]]
      @tr.load     = [wawe_8_9, wace_7_8]

      @tr.scheduleDepartureFractions = [[0.4,0.6],[0.6,0.2,0.2]]
      @tr.scheduleTimeSteps = [1, 1]
      @tr.scheduleDurations = [[1,1],[1,1,1]]

      # EXECUTE!!
      @tr.scheduleAggregateTimePeriods = { 10000..10090 => 2 }.to_a
      @tr.numberOfThreads = 1
      @tr.execute

      [11,12].each { |u|
        assert_in_delta(2, @db.get_value('link5_2data1', [1,1,'Walk', 2,u,1,1,1,0], "load"), TEST_DELTA, "walk access")

        assert_in_delta(2, @db.get_value('link5_2data1', [2,1,'PT',   2,u,1,1,1,1], "load"), TEST_DELTA, "PT leg")
        assert_in_delta(2, @db.get_value('link5_2data1', [6,1,'PT',   2,u,1,1,1,1], "load"), TEST_DELTA, "PT leg")
        assert_in_delta(2, @db.get_value('link5_2data1', [7,1,'PT',   2,u,1,1,2,1], "load"), TEST_DELTA, "PT leg")
        assert_in_delta(2, @db.get_value('link5_2data1', [4,1,'PT',   2,u,1,1,1,1], "load"), TEST_DELTA, "PT leg")
      }

      assert_in_delta(2, @db.get_value('link5_2data1', [5,1,'Walk',    2,11,1,1,2,0], "load"), TEST_DELTA, "walk egress")
      assert_in_delta(2, @db.get_value('link5_2data1', [5,1,'Vehicle', 2,12,1,1,2,0], "load"), TEST_DELTA, "car egress")
    }

  end

  def test_duration_missing
    assert_raises(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      # @tr.scheduleDurations = [5]
      @tr.execute
    }
  end


  # This test intentionally broken (note the double space :)
  def t  est_multi_purpose
    assert_nothing_raised(RuntimeError) {

      # create matrices
      walk,car,pt = ['Walk', 'Vehicle', 'PT'].to_mode
      pmturi = [[1,2], 'PT', 1, 1, 1, 1].to_pmturi
      pmturi.combine.each { |p| create_matrix(p, 2, [[1,2,1.0]]) }

      # schedule based properties
      @timePeriods = [10050,10052]
      @tr.scheduleStartTime = @timePeriods
      @tr.odMatrix = pmturi
      @tr.load     = pmturi

      @tr.scheduleTimeSteps = 2
      # @tr.scheduleDurations = [[1,1],[1,1,1]]

      # EXECUTE!!
      #@tr.scheduleAggregateTimePeriods = { 10000..10090 => 2 }.to_a
      @tr.numberOfThreads = 1
      @tr.execute

      assert_equal(14.5, @db.get_value('link5_2data1', [1,1,'Walk', 2,1,1,1,1,0], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [2,1,'PT',   2,1,1,1,1,1], "load"), "walk access")

      assert_equal(14.5, @db.get_value('link5_2data1', [6,1,'PT',   2,1,1,1,1,1], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [7,1,'PT',   2,1,1,1,2,1], "load"), "walk access")

      assert_equal(14.5, @db.get_value('link5_2data1', [4,1,'PT',   2,1,1,1,1,1], "load"), "walk access")
      assert_equal(14.5, @db.get_value('link5_2data1', [5,1,'Walk', 2,1,1,1,2,0], "load"), "walk egress")
    }

  end
end

# Test::Unit::UI::Console::TestRunner.run(TC_load, 3)
