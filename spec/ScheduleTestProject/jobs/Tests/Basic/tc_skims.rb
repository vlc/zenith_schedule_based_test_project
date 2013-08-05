require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_skim < OtScheduleTestCase

  def setup
    super
    set_fare_system({1 => 1})
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
    
  end

  def teardown
    reset_fare_systems()
    super
  end

  def test_basic_cost
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.skimMatrix = [1,1,1,1,1,1]
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.execute

      #     walk + wait + penalty + in vehicle time + fare + distance
    cost = 6 * 2 +    4 +       0 +              30 +  1.25 + (6*0)
    pmturi = [1,1,@timePeriods.first,1,1,1]
    {[1,1]=>99999.0, [1,2]=>cost, [2,2]=>99999.0, [2, 1] => 99999.0}.each { |(i,j),value|
      assert_in_delta(value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "Transfers skim")
    }
  end

  def test_multi_class
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    odMatrices = [11,12].map { |u|
      pmturi = [1,30,@timePeriods.first,u,1,1]
      create_matrix(pmturi, [[1,2,10]])
      pmturi
    }

    @tr.scheduleDurations = [5]
    @tr.defaultIntraZonalSkimValue = 99999.0

    # Properties that must be specified per class
    @tr.modes = [['Walk', 'Walk'].to_mode, ['Walk', 'Vehicle'].to_mode]
    @tr.odMatrix = odMatrices
    @tr.load = odMatrices
    @tr.skimMatrix = [[1,1,1,11,1,1], [1,1,1,12,1,1]]

    # Execute
    @tr.execute

      #     walk + wait + penalty + in vehicle time + fare + distance
    cost = 6 * 2 +    4 +       0 +              30 +  1.25 + (6*0)
    values = {[1,1]=>99999.0, [1,2]=>cost, [2,1]=>99999.0, [2,2]=>99999.0}
    check_skim_matrix_contents([1,1,@timePeriods.first,11,1,1], values, "Class 1 skim")
    #      walk +  drive + wait + penalty + in vehicle time + fare + distance
    cost =    6 +    0.6 +    4 +       0 +              30 +  1.25 + (6*0)
    values = {[1,1]=>99999.0, [1,2]=>cost, [2,1]=>99999.0, [2,2]=>99999.0}
    check_skim_matrix_contents([1,1,@timePeriods.first,12,1,1], values, "Class 2 skim")
  end

  def test_multiple_time_periods
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [4,4]
    @tr.scheduleTimeSteps = 4
    @tr.skimMatrix = [1,1,1,1,1,1]
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.numberOfThreads = 1
    @tr.execute

    values = {[1,1]=>99999.0, [1,2]=>0, [2,1]=>99999.0, [2,2]=>99999.0}
             #       walk + wait + penalty + in vehicle time + fare + distance
    values[[1,2]] = 6 * 2 +    4 +       0 +              30 +  1.25 + (6*0)
    check_skim_matrix_contents([1,1,@timePeriods.first,1,1,1], values, "Transfer Skim")

    values[[1,2]] = 6 * 2 +    0 +       0 +              30 +  1.25 + (6*0)
    check_skim_matrix_contents([1,1,@timePeriods.first+4,1,1,1], values, "Transfer Skim")

  end

  def test_time_aggregation
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [4,4]
    @tr.scheduleTimeSteps = 4
    @tr.skimMatrix = [1,1,1,1,1,1]
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.execute

    #       walk + wait + penalty + in vehicle time + fare + distance
    cost_1 = 6 * 2 +    4 +       0 +              30 +  1.25 + (6*0)
    cost_2 = 6 * 2 +    0 +       0 +              30 +  1.25 + (6*0)
    cost_av = (cost_1 + cost_2) / 2.0

    values = {[1,1]=>99999.0, [1,2]=>cost_av, [2,2]=>99999.0, [2,1]=>99999.0}
    check_skim_matrix_contents([1,1,2,1,1,1], values, "Transfer Skim")
  end

  def test_standard_skims
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.skimMatrix = [1,1,1,1,[11,12,13,14,15,16,17],1]
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.execute

      #     walk + wait + penalty + in vehicle time + fare + distance
    cost = 6 * 2 +    4 +       0 +              30 +  1.25 + (6*0)
    skimDescriptions = ['Cost', 'Distance', 'Time', 'Wait', 'Penalty', 'Fare', 'Transfers']
    (11..17).to_a.zip([cost, 6.0, 46.0, 4.0, 0.0, 1.25, 0.0], skimDescriptions).each { |result, expected_value, desc|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,2,1,result,1], 1, 2), TEST_DELTA, "Standard Skim: #{desc}")
    }
  end

  def test_route_factors
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.skimMatrix = [1,1,1,1,[11,12,13,14,15,16,17],1]
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.routeFactors = [[40, 0, 0], [[30,31,32], *[0, 0, 0, 0, 1]]]
    @tr.execute

    fare = 1.25 # route factor is zero for everything EXCEPT fare
    skimDescriptions = ['Cost', 'Distance', 'Time', 'Wait', 'Penalty', 'Fare', 'Transfers']
    (11..17).to_a.zip([fare, 6.0, 46.0, 4.0, 0.0, 1.25, 0.0], skimDescriptions).each { |result, expected_value, desc|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,2,1,result,1], 1, 2), TEST_DELTA, "Standard Skim: #{desc}")
    }
  end

  def test_multiple_od_matrices

    # schedule based properties
    @timePeriods = [tt(40),tt(50)]
    @timePeriods.zip([10.0, 5.0]).each { |t, value| create_matrix([1,30,t,1,1,1], [[1,2,value]]) }
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [[5,5],[5]]
    @tr.skimMatrix = [1,1,1,1,1,1]
    @tr.odMatrix = [1,30,@timePeriods,1,1,1]

    # EXECUTE!!
    @tr.numberOfThreads = 1
    @tr.execute

    [tt(40),tt(45),tt(50)].zip([57.25, 52.25, 47.25]).each { |t, expected_value|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,t,1,1,1], 1, 2), TEST_DELTA, "cost skim for time #{t}")
    }

    # EXECUTE! Now with time period aggregation
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.execute

    average_cost = [57.25, 52.25, 47.25].mean
    assert_in_delta(average_cost, @db.get_skim_value([1,1,2,1,1,1], 1, 2), TEST_DELTA, "averaged cost skim")

    # EXECUTE! Now with time period aggregation that combines across multiple od matrices
    @tr.scheduleAggregateTimePeriods = { tt(40)..tt(44) => 2, tt(45)..tt(90) => 3 }.to_a
    @tr.execute

    [2,3].zip([57.25, (52.25+47.25)/2]).each { |t,expected_value|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,t,1,1,1], 1, 2), TEST_DELTA, "cost skim for time #{t}")
    }

    # EXECUTE! Now with time period aggregation along with departure profiles
    @tr.scheduleAggregateTimePeriods = { tt(40)..tt(44) => 2, tt(45)..tt(90) => 3 }.to_a
    @tr.scheduleDepartureFractions = [[0.2,0.8], [1.0]]
    @tr.execute

    [2,3].zip([57.25, (8.0*52.25+5.0*47.25)/13]).each { |t,expected_value|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,t,1,1,1], 1, 2), TEST_DELTA, "cost skim for time #{t}")
    }
  end
end

OtTestCaseRunner.run(__FILE__)