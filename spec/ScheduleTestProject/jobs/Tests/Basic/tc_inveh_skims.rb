require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_in_veh_skim < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    reset_fare_systems()
    super
  end

  def test_basic_skims
    assert_nothing_raised(RuntimeError) {

      # define the fare systems
      set_fare_system({1 => 1}) # 1 => distance based, 2 => time based

      skim_results = [11,12,13,14,15,16]

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.inVehicleSkimMatrix = [2,1,1,1,skim_results,1]
      @tr.defaultIntraZonalSkimValue = 99999.0
      @tr.execute

      # cost, distance, time, wait, penalty, fare
      skim_values = [30+4+1.25, 4, 30, 4, 0, 1.25]

      skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,1,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }
    }
  end

  def test_by_mode_skims
    assert_nothing_raised(RuntimeError) {

      # define the fare systems
      set_fare_system({1 => 1}) # 1 => distance based, 2 => time based

      skim_results = [11,12,13,14,15,16]

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.skimsPerMode = true
      @tr.inVehicleSkimMatrix = [2,1,1,1,skim_results,1]
      @tr.defaultIntraZonalSkimValue = 99999.0
      @tr.execute

      # cost, distance, time, wait, penalty, fare
      skim_values = [30+4+1.25, 4, 30, 4, 0, 1.25]

      skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,30,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }
    }
  end
end

OtTestCaseRunner.run(__FILE__)
