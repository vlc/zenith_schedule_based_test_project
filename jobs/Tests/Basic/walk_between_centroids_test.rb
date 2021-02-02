require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_walk_between_centroid < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.walkBetweenCentroids = true
  end

  def teardown
    reset_fare_systems()
    super
  end

  def test_basic
    assert_nothing_raised(RuntimeError) {
    
    	set_link_speeds({[2,1] => 60.0, [4,1] => 60.0, [6,1] => 60.0, [7,2] => 60.0})

      # schedule based properties
      @tr.execute

      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',tt(50),1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'Walk',tt(56),1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [6,1,'Walk',tt(57),1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'Walk',tt(58),1,1,1,2,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [4,1,'Walk',tt(59),1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Walk',tt(60),1,1,1,2,0], "load"), "walk")
      
      assert_true(@db.get_value('link5_2data1', [2,1,'Walk',tt(56),1,1,1,1,0], "cost") > 0.0)

    }
  ensure
  	set_link_speeds({[2,1] => 0.0, [4,1] => 0.0, [6,1] => 0.0, [7,2] => 0.0})
  end
  
  def test_time_aggregation
    assert_nothing_raised(RuntimeError) {
    
    	set_link_speeds({[2,1] => 60.0, [4,1] => 60.0, [6,1] => 60.0, [7,2] => 60.0})

      # schedule based properties
      @tr.scheduleAggregateTimePeriods = { tt(50)..tt(90) => 3 }.to_a
      @tr.execute

      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',3,1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'Walk',3,1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [6,1,'Walk',3,1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'Walk',3,1,1,1,2,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [4,1,'Walk',3,1,1,1,1,0], "load"), "walk")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Walk',3,1,1,1,2,0], "load"), "walk")
    }
  ensure
  	set_link_speeds({[2,1] => 0.0, [4,1] => 0.0, [6,1] => 0.0, [7,2] => 0.0})
  end
  
  def test_routeFactors
    assert_nothing_raised(RuntimeError) {
    
    	set_link_speeds({[2,1] => 60.0, [4,1] => 60.0, [6,1] => 60.0, [7,2] => 60.0})
    	
    	# route factors we'll be testing
      factors               = [1, 60, 60, 60, 0]
      factors_incl_distance = [2, 60, 60, 60, 0]
      factors_150_penalty   = [0, 60, 60, 1.5*60, 0]
      factors_150_wait      = [0, 60, 1.5*60, 60, 0]
      
			@tr.scheduleAggregateTimePeriods = { tt(50)..tt(90) => 3 }.to_a
      @tr.routeFactors = [[40, 1, 60], [[30,31,32], *factors]]
      @tr.execute
      
      cost_of_fast_legs = 1 * 1 + 1/60.0 * 60.0 # 1 min + 1 km = 2
      assert_equal(6 + 1, 						@db.get_value('link5_2data1', [1,1,'Walk',3,1,1,1,1,0], "cost"), "walk")
      assert_equal(cost_of_fast_legs, @db.get_value('link5_2data1', [2,1,'Walk',3,1,1,1,1,0], "cost"), "walk")
      assert_equal(cost_of_fast_legs, @db.get_value('link5_2data1', [6,1,'Walk',3,1,1,1,1,0], "cost"), "walk")
      assert_equal(cost_of_fast_legs, @db.get_value('link5_2data1', [7,1,'Walk',3,1,1,1,2,0], "cost"), "walk")
      assert_equal(cost_of_fast_legs, @db.get_value('link5_2data1', [4,1,'Walk',3,1,1,1,1,0], "cost"), "walk")
      assert_equal(6 + 1, 						@db.get_value('link5_2data1', [5,1,'Walk',3,1,1,1,2,0], "cost"), "walk")
		}
  ensure
  	set_link_speeds({[2,1] => 0.0, [4,1] => 0.0, [6,1] => 0.0, [7,2] => 0.0})
  end
  
  def test_skimming
  	assert_nothing_raised(RuntimeError) {
    	set_link_speeds({[2,1] => 60.0, [4,1] => 60.0, [6,1] => 60.0, [7,2] => 60.0})
    	
			@tr.scheduleAggregateTimePeriods = { tt(50)..tt(90) => 3 }.to_a
      @tr.skimMatrix = [1,1,1,1,[1,2,3],1]
      @tr.execute
      
      assert_equal(6*2 + 4*1, @db.get_skim_value([1,1,3,1,1,1], 1, 2))
      assert_equal(6, 				@db.get_skim_value([1,1,3,1,2,1], 1, 2))
      # assert_equal(6*2 + 4*1, @db.get_skim_value([1,1,3,1,3,1], 1, 2))
      
		}
  ensure
  	set_link_speeds({[2,1] => 0.0, [4,1] => 0.0, [6,1] => 0.0, [7,2] => 0.0})
  end	

end

OtTestCaseRunner.run(__FILE__)