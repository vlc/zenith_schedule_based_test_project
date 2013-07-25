require 'utils/spec/ot_test_suite'

class TC_logit < OtTestCase

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
    super
  end

  def test_logit_factors
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a

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