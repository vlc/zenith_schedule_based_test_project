require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_aet_skim < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
  end

  def teardown
    reset_fare_systems()
    @tr = nil
    super
  end

  def test_basic_cost
    skim_results = [11,12,13,14,15]

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.skimMatrix = [1,1,1,1,1,1]
    @tr.accessSkimMatrix   = [2,1,1,1,skim_results,1]
    @tr.egressSkimMatrix   = [3,1,1,1,skim_results,1]
    @tr.transferSkimMatrix = [4,1,1,1,skim_results,1]
    @tr.defaultIntraZonalSkimValue = 99999.0
    @tr.logitParameters = 0.1
    @tr.execute

    # cost, distance, time, wait, penalty
    access_skim_values = [6, 1, 6, 4, 0]
    transfer_skim_values = [0, 0, 0, 7.749169987, 5]
    egress_skim_values = [6, 1, 6, 0, 0]

    access_skim_values.zip(skim_results).each { |value, result|
      #~ assert_in_delta(value, @db.get_skim_value(pmturi, 1, 2), TEST_DELTA, "Transfers skim")
      pmturi = [2,1,@timePeriods.first,1,result,1]
      {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
        assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "Transfers skim")
      }
    }

    egress_skim_values.zip(skim_results).each { |value, result|
      pmturi = [3,1,@timePeriods.first,1,result,1]
      {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
        assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "Transfers skim")
      }
    }

    transfer_skim_values.zip(skim_results).each { |value, result|
      pmturi = [4,1,@timePeriods.first,1,result,1]
      {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
        assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "Transfers skim")
      }
    }
  end
end

OtTestCaseRunner.run(__FILE__)