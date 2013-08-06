require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_minProbability < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
  end

  def teardown
    super
  end

  def test_simple
    assert_nothing_raised(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
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