require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_modes < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true

    # Single time period of 5 minutes duration
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
  end

  def teardown
    super
  end

  def test_modes
    assert_nothing_raised(RuntimeError) {
      @tr.modes = [['Walk','Vehicle'].to_mode]
      @tr.execute

      assert_equal(10, @db.get_value('link5_2data1', [1,1,'Walk',    t(50),1,1,1,1,0], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [2,1,'PT',      t(60),1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [6,1,'PT',      t(66),1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [7,1,'PT',      t(71),1,1,1,2,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [4,1,'PT',      t(76),1,1,1,1,1], "load"), "walk access")
      assert_equal(10, @db.get_value('link5_2data1', [5,1,'Vehicle', t(90),1,1,1,2,0], "load"), "walk egress")

      # transit line table
      assert_equal(10, @db.get_value('transitline5data1', [1,1,'PT', t(60),1,1,1], "passengers"),   "passengers")
      assert_equal(40, @db.get_value('transitline5data1', [1,1,'PT', t(60),1,1,1], "passdistance"), "passenger distance") #  4 km * 10 passengers
      assert_equal(5 , @db.get_value('transitline5data1', [1,1,'PT', t(60),1,1,1], "passtime"),     "passenger time") # half hour * 10 passengers
    }

  end
end

OtTestCaseRunner.run(__FILE__)