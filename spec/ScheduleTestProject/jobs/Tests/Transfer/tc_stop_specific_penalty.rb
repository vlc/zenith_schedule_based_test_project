require 'utils/spec/ot_test_suite'

class TC_stop_specific_penalty < OtTestCase

  def setup
    clearOutputTables
    @tr = OtTransit.new
    @timePeriods = [10050]
    @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], 2, [[1,2,10]]) }
    @tr.loadMatricesFromSkimCube = true
    @tr.odMatrix = [1,30,@timePeriods,1,1,1]
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    reset_stop_access_penalties()
    @tr = nil
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
      
      assert_in_delta(15, @db.get_skim_value([1,1,10050,1,15,1], 1, 2), TEST_DELTA, "Penalty")
    }
  end
end

OtTestCaseRunner.run(__FILE__)