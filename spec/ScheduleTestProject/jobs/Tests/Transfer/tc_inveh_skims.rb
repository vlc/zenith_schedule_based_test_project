require 'utils/spec/ot_test_suite'

class TC_in_veh_skim < OtTestCase

  def setup
    clearOutputTables
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
    reset_fare_systems()
    super
  end

  def test_basic_skims
    assert_nothing_raised(RuntimeError) {

      # define the fare systems
      set_fare_system({3 => 1, 4 => 1, 5 => 1}) # 1 => distance based, 2 => time based

      skim_results = [11,12,13,14,15,16]

      # schedule based properties
      @tr.scheduleBased = true
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      #@tr.skimMatrix = [1,1,1,1,1,1]
      @tr.inVehicleSkimMatrix = [2,1,1,1,skim_results,1]
      @tr.defaultIntraZonalSkimValue = 99999.0
      @tr.logitParameters = 0.1
      @tr.execute

      # cost, distance, time, wait, penalty, fare
      skim_values = [29.15033201, 4, 11.15116202, 11.749169987, 5, 1.25]

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
      set_fare_system({3 => 1, 4 => 1, 5 => 1}) # 1 => distance based, 2 => time based

      skim_results = [11,12,13,14,15,16]

      # schedule based properties
      @tr.scheduleBased = true
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.skimsPerMode = true
      @tr.skimMatrix = [1,1,1,1,skim_results,1]
      @tr.inVehicleSkimMatrix = [2,1,1,1,skim_results,1]
      @tr.defaultIntraZonalSkimValue = 99999.0
      @tr.logitParameters = 0.1
      @tr.execute

      #                        cost,    distance,        time,        wait,     penalty,        fare
      pt_skim_values = [19.72498132, 2.649501992, 6.649501992, 9.498339973, 2.749169987, 0.827969372]
      pt_skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,30,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }

      #                         cost,    distance,        time,        wait,     penalty,        fare
      bus_skim_values = [9.425350681, 1.350498008, 4.501660027, 2.250830013, 2.250830013, 0.422030628]
      bus_skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,32,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }

      ###########################################################
      # Now we try it again with multiple fare schemes per path #
      ###########################################################

      set_fare_system({3 => 1, 4 => 1, 5 => 2}) # 1 => distance based, 2 => time based
      @tr.execute

      #                        cost,    distance,        time,        wait,     penalty,        fare
      pt_skim_values = [19.77383502, 2.481250977, 6.481250977, 8.937503255, 2.468751628, 1.886329163]
      pt_skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,30,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }

      #                         cost,    distance,        time,        wait,     penalty,       fare
      bus_skim_values = [10.59960256, 1.518749023, 5.062496745, 2.531248372, 2.531248372, 0.47460907]
      bus_skim_values.zip(skim_results).each { |value, result|
        pmturi = [2,32,@timePeriods.first,1,result,1]
        {[1,1]=>99999.0, [1,2]=>value, [2,2]=>99999.0}.each { |(i,j),expected_value|
          assert_in_delta(expected_value, @db.get_skim_value(pmturi, i, j), TEST_DELTA, "In Vehicle Skims")
        }
      }
    }
  end
end

OtTestCaseRunner.run(__FILE__)