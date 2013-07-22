require 'utils/spec/ot_test_suite'

class TC_loading_profile < OtTestCase

  def setup
    clearOutputTables
    @tr = OtTransit.new
    @tr.loadMatricesFromSkimCube = true
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    @tr = nil
    super
  end

  def test_single_matrix
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @timePeriods = [10050]
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      # loading profile defaults to uniform distribution (#@tr.scheduleDepartureFractions = [1.0])
      # time step defaults to 5 minutes

      @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], [[1,2,10]]) }
      @tr.odMatrix = [1,30,@timePeriods,1,1,1]
      @tr.load = [1,30,10,1,1,1]

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
    }

  end

	def test_uniform_distribution
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = 10050
      @tr.scheduleDurations = [30]
  		@tr.scheduleTimeSteps = 10
  		# @tr.scheduleAggregateTimePeriods = { 10000..10539 => 2, 10540..10720 => 3 }.to_a
      
      # loading profile defaults to uniform distribution 
      # @tr.scheduleDepartureFractions = [1.0/3.0] * 3

      create_matrix([1,30,10050,1,1,1], [[1,2,10]])
      @tr.odMatrix = [1,30,10050,1,1,1]
      @tr.load = [1,30,10,1,1,1]

      # EXECUTE!!
      @tr.execute

		  assert_in_delta(10/3.0, @db.get_value('link5_2data1', [1,1,'Walk',10050,1,1,1,1,0], "load"), TEST_DELTA, "walk access")
      assert_in_delta(10/3.0, @db.get_value('link5_2data1', [2,1,'PT',  10060,1,1,1,1,1], "load"), TEST_DELTA, "walk access")
      assert_in_delta(10/3.0, @db.get_value('link5_2data1', [6,1,'PT',  10066,1,1,1,1,1], "load"), TEST_DELTA, "walk access")
      assert_in_delta(10/3.0, @db.get_value('link5_2data1', [7,1,'PT',  10070,1,1,1,2,1], "load"), TEST_DELTA, "walk access")
      assert_in_delta(10/3.0, @db.get_value('link5_2data1', [4,1,'PT',  10076,1,1,1,1,1], "load"), TEST_DELTA, "walk access")
      assert_in_delta(10/3.0, @db.get_value('link5_2data1', [5,1,'Walk',10090,1,1,1,2,0], "load"), TEST_DELTA, "walk egress")

      # transit line table
      assert_in_delta(10/3.0, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passengers"),   TEST_DELTA, "passengers")
      assert_in_delta(40/3.0, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passdistance"), TEST_DELTA, "passenger distance") #  4 km * 10 passengers
      assert_in_delta(5/3.0,  @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passtime"),     TEST_DELTA, "passenger time") # half hour * 10 passengers
      
      # NOTE: passengers leaving after the first departure will miss the service and not be assigned!
    }
  end
end

OtTestCaseRunner.run(__FILE__)