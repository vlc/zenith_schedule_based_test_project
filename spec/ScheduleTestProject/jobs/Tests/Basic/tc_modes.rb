require 'utils/spec/ot_test_suite'

class TC_modes < OtTestCase

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

    # Single time period of 5 minutes duration
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
  end

  def teardown
    @tr = nil
    super
  end

  def test_modes
    assert_nothing_raised(RuntimeError) {
      @tr.modes = [['Walk','Vehicle'].to_mode]
      @tr.execute

      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',    10050,1,1,1,1,0], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'PT',      10060,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [6,1,'PT',      10066,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',      10070,1,1,1,2,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [4,1,'PT',      10076,1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Vehicle', 10090,1,1,1,2,0], "load"), "walk egress")

      # transit line table
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT',10060,1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers
    }

  end
end

OtTestCaseRunner.run(__FILE__)