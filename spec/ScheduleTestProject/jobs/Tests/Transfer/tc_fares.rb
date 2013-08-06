require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_fares < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
  end

  def teardown
    reset_fare_systems()
    reset_fare_zones()
    super
  end

  def check_load_based_on_usage(usage)
    assert_in_delta(10,       @db.get_value('link5_2data1', [1,1,'Walk',tt(50),1,1,1,1,0], "load"), TEST_DELTA, "walk access")
    assert_in_delta(10,       @db.get_value('link5_2data1', [2,1,'PT',  tt(60),1,1,1,1,3], "load"), TEST_DELTA, "single transit line")

    assert_in_delta(usage[0], @db.get_value('link5_2data1', [6,1,'Bus',tt(70),1,1,1,1,4],  "load"), TEST_DELTA, "optional transit line 4")
    assert_in_delta(usage[0], @db.get_value('link5_2data1', [7,1,'Bus',tt(73),1,1,1,2,4],  "load"), TEST_DELTA, "optional transit line 4")
    assert_in_delta(usage[0], @db.get_value('link5_2data1', [4,1,'Bus',tt(76),1,1,1,1,4],  "load"), TEST_DELTA, "optional transit line 4")

    assert_in_delta(usage[1], @db.get_value('link5_2data1', [6,1,'PT',tt(75),1,1,1,1,5],   "load"), TEST_DELTA, "optional transit line 5")
    assert_in_delta(usage[1], @db.get_value('link5_2data1', [7,1,'PT',tt(76),1,1,1,2,5],   "load"), TEST_DELTA, "optional transit line 5")
    assert_in_delta(usage[1], @db.get_value('link5_2data1', [4,1,'PT',tt(77),1,1,1,1,5],   "load"), TEST_DELTA, "optional transit line 5")

    assert_in_delta(usage[0], @db.get_value('link5_2data1', [5,1,'Walk',tt(80),1,1,1,2,0], "load"), TEST_DELTA, "walk egress from line 4")
    assert_in_delta(usage[1], @db.get_value('link5_2data1', [5,1,'Walk',tt(78),1,1,1,2,0], "load"), TEST_DELTA, "walk egress from line 5")
  end

  def test_simple
    # define the fare systems
    set_fare_system({4 => 1, 5 => 2}) # 1 => distance based, 2 => time based


    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters  = [0.1]

    # EXECUTE!!
    @tr.execute

    # the different fare systems used by the two competing paths should equalise their total costs... 50/50 load
    check_load_based_on_usage([5,5])
  end

  def test_route_factors
    # define the fare systems
    set_fare_system({4 => 1, 5 => 2}) # 1 => distance based, 2 => time based

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters   = [0.1]
    @tr.routeFactors      = [[40, 0, 60], [[30,31,32], 0, 60, 60, 60, 2]] # double fares

    # EXECUTE!!
    @tr.execute

    # the different fare systems used by the two competing paths should equalise their total costs... 50/50 load
    usage = calculate_usage([43.0, 45.0], -0.1) # see calculations.xls
    usage.map! {|u| u * 10 }
    check_load_based_on_usage(usage)
  end

  def test_chaining
    # define the fare systems
    set_fare_system({3=>1, 4=>1, 5=>2}) # distance, distance, time

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters  = [0.1]

    # EXECUTE!!
    @tr.execute

    usage = calculate_usage([42.25, 42.5], -0.1) # see calculations.xls
    usage.map! {|u| u * 10 }
    check_load_based_on_usage(usage)
  end

  def test_zone_type

    [1,2,3,4].each { |stopnr| set_stop_zone(stopnr,3) }

    # define the fare systems
    set_fare_system({3=>3, 4=>3, 5=>3}) # all stop type - based

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters  = [0.1]

    # EXECUTE!!
    @tr.execute

    # Check the output loads
    usage = calculate_usage([42.0, 40.0], -0.1) # see calculations.xls
    check_load_based_on_usage(usage.map! {|u| u * 10 } )

  end

  def test_stop_to_stop
    # define the fare systems
    set_fare_system({3=>4, 4=>4, 5=>4}) # stop to stop - based

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters  = [0.1]
    @tr.skimMatrix = [1,1,1,1,[1,2,3,4,5,6,7],1]

    # EXECUTE!!
    @tr.execute

    # Check the output loads
    usage = calculate_usage([42.5, 40.5], -0.1) # see calculations.xls
    check_load_based_on_usage(usage.map! {|u| u * 10 } )

    # Check the skims for fares
    check_skim_matrix_contents([1,1,tt(50),1,6,1], {[1,2]=>1.5}, "Fares Skim")
  end

  def test_stoptype_to_stoptype

    # define the fare systems
    set_fare_system({3=>5, 4=>5, 5=>5}) #  stoptype to stoptype - based
    [1,2,3,4].each { |s|  set_stop_zone(s,s)     }

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.logitParameters  = [0.1]
    @tr.skimMatrix = [1,1,1,1,[1,2,3,4,5,6,7],1]

    # EXECUTE!!
    @tr.execute

    # Check the output loads
    usage = calculate_usage([43.0, 41.0], -0.1) # see calculations.xls
    check_load_based_on_usage(usage.map! {|u| u * 10 } )

    # Check the skims for fares
    check_skim_matrix_contents([1,1,tt(50),1,6,1], {[1,2]=>2.0}, "Fares Skim")
  end

  def test_missing_fareZone

    # define the fare systems
    set_fare_system({3=>3, 4=>3, 5=>3}) # stopTypeTable - based

    # Don't define a fareZone for stop 1... transit line 3 should crack the shits
    [2,3,4].each { |stopnr| set_stop_zone(stopnr,3) }

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]

    # EXECUTE!!
    assert_raises(RuntimeError) {
      @tr.execute
    }

  end

  def test_missing_fareSystem
    # define the fare systems as some random number which doesn't have a fareSystem associated
    set_fare_system({3=>99, 4=>99, 5=>99})

    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]

    # EXECUTE!!
    assert_raises(RuntimeError) {
      @tr.execute
    }
  end

end

OtTestCaseRunner.run(__FILE__)