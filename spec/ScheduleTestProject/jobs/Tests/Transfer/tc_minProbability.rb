require 'utils/spec/ot_test_suite'

class TC_minProbability < OtTestCase

  def setup
    OtTestUtils.clearOutputTables
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

  def test_simple
    assert_nothing_raised(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.minProbability = [0.5] # 50% means that only the best of the TWO paths can be chosen (unless they both have same cost)
      @tr.execute

      usage = calculate_usage([30,28], -0.1)
      assert_in_delta(10, @db.get_value('link5_2data1', [6,1,'PT',2,1,1,1,1,5], "load"), 0.01, "cheaper path")
    }
  end
end

OtTestCaseRunner.run(__FILE__)