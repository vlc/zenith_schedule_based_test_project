require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_stop_specific_penalty < OtScheduleTestCase

  def setup
    super
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    reset_stop_access_penalties()
    super
  end

  def test_basic
    assert_nothing_raised(RuntimeError) {

      # define the access penalties
      set_stop_access_penalty(1,40,10,0,10)

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.logitParameters = 0.1
      @tr.skimMatrix = [1,1,1,1,[0,0,0,0,15,0,0],1]
      @tr.execute
      
      assert_in_delta(15, @db.get_skim_value([1,1,tt(50),1,15,1], 1, 2), TEST_DELTA, "Penalty")
    }
  end
end

OtTestCaseRunner.run(__FILE__)