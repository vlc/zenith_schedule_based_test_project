require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_logit < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
  end

  def teardown
    super
  end

  def test_logit_factors
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation

      # Calculation of costs (see calculations.xls in variant directory)
      costs                = [27+9+5,20+14+5]

      # property combinations we'll be testing
      default                 = [999999]
      small                   = [0.1]
      zero                    = [0.0]

      # execute with default
      usage = calculate_usage(costs, -999999)
      @tr.execute
      assert_in_delta(10, @db.get_value('link5_2data1', [4,1,'PT',2,1,1,1,1,5], "load"), 0.01, "100% on the cheapest path")
      load_on_line_4 = OtQuery.execute_to_a("SELECT sum(load) FROM 'link5_2data1' WHERE transitlinenr = 4").flatten.first
      assert_equal(0, load_on_line_4, "load on expensive line")

      @tr.logitParameters  = small
      @tr.execute
      usage = calculate_usage(costs, -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "cheaper path")

      @tr.logitParameters = zero # 50/50 split
      @tr.execute
      usage = calculate_usage(costs, -0.0)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "cheaper path")
    }
  end
end

OtTestCaseRunner.run(__FILE__)