require 'utils/spec/ot_test_suite'

class TC_pathBuild < OtTestCase

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

  def test_path_factors
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.routeFactors = [[0, 0, 60, 60, 60, 0]]
      #@tr.scheduleAnimateLoads = true
      @tr.logitParameters  = [0.1]

      # Calculation of costs (see calculations.xls in variant directory)
      costs                = [27+9+5,20+14+5]
      costs_to_stop_4      = costs.map { |e| e-6.0 } # remove the walk egress time
      diff_percentage_cost = 100 * (costs_to_stop_4[0]-costs_to_stop_4[1])/costs_to_stop_4.min # 6.06%
      # Calculation of times
      times                = [27+9,20+14] # the time doesn't include penalty!
      times_to_stop_4      = times.map { |e| e-6.0 } # remove the walk egress time
      diff_percentage_time = 100 * (times_to_stop_4[0]-times_to_stop_4[1])/times_to_stop_4.min # 7.143%

      # property combinations we'll be testing
      default                 = [[1.3, 0.0], [1.5, 0.0], [1.0, 1.0]]
      shortest_path           = [[1.0, 0.0], [1.5, 0.0], [1.0, 1.0]]
      just_shortest_path_cost = [[(100 + diff_percentage_cost).floor / 100.0, 0.0], [1.5, 0.0], [1.0, 1.0]]
      find_second_option_cost = [[(100 + diff_percentage_cost).ceil  / 100.0, 0.0], [1.5, 0.0], [1.0, 1.0]]
      just_shortest_path_time = [[1.5, 0.0], [(100 + diff_percentage_time).floor / 100.0, 0.0], [1.0, 1.0]]
      find_second_option_time = [[1.5, 0.0], [(100 + diff_percentage_time).ceil  / 100.0, 0.0], [1.0, 1.0]]

      @tr.schedulePathFactors = shortest_path
      @tr.execute
      assert_in_delta(10, @db.get_value('link5_2data1', [4,1,'PT',2,1,1,1,1,5], "load"), 0.01, "100% on the cheapest path")
      load_on_line_4 = OtQuery.execute_to_a("SELECT sum(load) FROM 'link5_2data1' WHERE transitlinenr = 4").flatten.first
      assert_equal(0, load_on_line_4, "load on expensive line")

      @tr.schedulePathFactors = just_shortest_path_cost
      @tr.execute
      assert_in_delta(10, @db.get_value('link5_2data1', [4,1,'PT',2,1,1,1,1,5], "load"), 0.01, "100% on the cheapest path")
      load_on_line_4 = OtQuery.execute_to_a("SELECT sum(load) FROM 'link5_2data1' WHERE transitlinenr = 4").flatten.first
      assert_equal(0, load_on_line_4, "load on expensive line")

      @tr.schedulePathFactors = find_second_option_cost
      @tr.execute
      usage = calculate_usage(costs, -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "cheaper path")

      @tr.schedulePathFactors = just_shortest_path_time
      @tr.execute
      assert_in_delta(10, @db.get_value('link5_2data1', [4,1,'PT',2,1,1,1,1,5], "load"), 0.01, "100% on the cheapest path")
      load_on_line_4 = OtQuery.execute_to_a("SELECT sum(load) FROM 'link5_2data1' WHERE transitlinenr = 4").flatten.first
      assert_equal(0, load_on_line_4, "load on expensive line")

      @tr.schedulePathFactors = find_second_option_time
      @tr.execute
      usage = calculate_usage(costs, -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "cheaper path")
    }
  end
end

OtTestCaseRunner.run(__FILE__)