require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_skim < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    super
  end

  def test_standard_skims
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.skimMatrix = [1,1,1,1,[11,12,13,14,15,16,17],1]
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.logitParameters = [0.1]
    @tr.execute

    skim_descriptions = ['Cost', 'Distance', 'Time', 'Wait', 'Penalty', 'Fare', 'Transfers']
    expected_values = [40.48020415, 6.689974481, 37.03033175, 5.379948962, 3.449872406, 0, 0.689974481] # see calculations.xls in variant directory

    (11..17).to_a.zip(expected_values, skim_descriptions).each { |result, expected_value, desc|
      assert_in_delta(expected_value, @db.get_skim_value([1,1,2,1,result,1], 1, 2), TEST_DELTA, "Standard Skim: #{desc}")
    }
  end

  def test_aggregation
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5,5]
    @tr.skimMatrix = [1,1,1,1,[11,12,13,14,15,16,17],1]
    @tr.scheduleAggregateTimePeriods = @all_time_to_single_period_aggregation
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.logitParameters = [0.1]


    # Execute: the second time period has no connections to the destination, therefore costs should be infinite
    @tr.execute
    (11..17).to_a.each { |result|
      assert_equal(99999.0, @db.get_skim_value([1,1,2,1,result,1], 1, 2))
    }
  end
end

OtTestCaseRunner.run(__FILE__)