require 'utils/spec/ot_test_suite'

class TC_routeFactors < OtTestCase

  def setup
    @db = TestAssistant.new
    @tr = OtTransit.new
    @timePeriods = [10050]
    @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], [[1,2,10]]) }
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

  def test_route_factors
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      # @tr.animateScheduleLoads = true
      @tr.scheduleAggregateTimePeriods = { 10000..10100 => 2 }.to_a

      @tr.logitParameters  = 0.1

      # route factors we'll be testing
      factors               = [0, 60, 60, 60, 0]
      factors_incl_distance = [2, 60, 60, 60, 0]
      factors_150_penalty   = [0, 60, 60, 1.5*60, 0]
      factors_150_wait      = [0, 60, 1.5*60, 60, 0]

      # defaults
      @tr.execute
      usage = calculate_usage([27 + 6 + 5, 42 + 4], -0.1)
      assert_in_delta(10 * usage[0], @db.get_value('link5_2data1', [9,1,'Train',2,1,1,1,1,2], "load"), 0.01, "path 1")
      assert_in_delta(10 * usage[1], @db.get_value('link5_2data1', [6,1,'Bus'  ,2,1,1,1,1,1], "load"), 0.01, "path 2")

      @tr.routeFactors = [[40, 0, 60], [[30,31,32], *factors_150_penalty]]
      @tr.execute
      usage = calculate_usage([27 + 6 + 1.5*5, 42 + 4], -0.1)
      assert_in_delta(10 * usage[0], @db.get_value('link5_2data1', [9,1,'Train',2,1,1,1,1,2], "load"), 0.01, "path 1")
      assert_in_delta(10 * usage[1], @db.get_value('link5_2data1', [6,1,'Bus'  ,2,1,1,1,1,1], "load"), 0.01, "path 2")

      @tr.routeFactors = [[40, 0, 60], [[30,32], *factors_150_penalty], [31, *factors]]
      @tr.execute
      usage = calculate_usage([27 + 6 + 5, 42 + 4], -0.1)
      assert_in_delta(10 * usage[0], @db.get_value('link5_2data1', [9,1,'Train',2,1,1,1,1,2], "load"), 0.01, "path 1")
      assert_in_delta(10 * usage[1], @db.get_value('link5_2data1', [6,1,'Bus'  ,2,1,1,1,1,1], "load"), 0.01, "path 2")

      @tr.routeFactors = [[40, 0, 60], [[30,31,32], *factors_150_wait]]
      @tr.execute
      usage = calculate_usage([27 + 1.5*6 + 5, 42 + 1.5*4], -0.1)
      assert_in_delta(10 * usage[0], @db.get_value('link5_2data1', [9,1,'Train',2,1,1,1,1,2], "load"), 0.01, "path 1")
      assert_in_delta(10 * usage[1], @db.get_value('link5_2data1', [6,1,'Bus'  ,2,1,1,1,1,1], "load"), 0.01, "path 2")

      @tr.routeFactors = [[40, 0, 60], [[30,31,32], *factors_incl_distance]]
      @tr.execute
      usage = calculate_usage([27 + 6 + 5 + 2*7, 42 + 4 + 2*6], -0.1)
      assert_in_delta(10 * usage[0], @db.get_value('link5_2data1', [9,1,'Train',2,1,1,1,1,2], "load"), 0.01, "path 1")
      assert_in_delta(10 * usage[1], @db.get_value('link5_2data1', [6,1,'Bus'  ,2,1,1,1,1,1], "load"), 0.01, "path 2")

    }

  end
end

OtTestCaseRunner.run(__FILE__)