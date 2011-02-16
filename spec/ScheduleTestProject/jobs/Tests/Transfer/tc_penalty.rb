require 'Utils/TestAssistant'
require 'utils/ot_test_suite'
require 'test/unit'

class TC_penalty < OtTestCase

  def setup
    OtTestUtils.clearOutputTables
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
    @tr = nil
    super
  end

  def get_pt_to_bus_penalty()
    return OtQuery.execute_to_a(<<-SQL).flatten.first
           SELECT penalty FROM '#{File.join($Ot.projectDirectory, 'mode2mode.db')}'
           WHERE modea = #{'PT'.to_mode} AND modeb = #{'Bus'.to_mode}
           SQL
  end


  def set_pt_to_bus_penalty(new_value)
    OtQuery.execute(<<-SQL)
    UPDATE '#{File.join($Ot.projectDirectory, 'mode2mode.db')}'
    SET penalty = #{new_value}
    WHERE modea = #{'PT'.to_mode} and modeb = #{'Bus'.to_mode}
    SQL
  end

  def test_penalty
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.logitParameters  = [0.1]

      # Calculation of costs (see calculations.xls in variant directory)
      costs_default_penalty           = [27+9+5,20+14+5]
      costs_pt_to_bus_penalty_doubled = [27+9+10,20+14+5]

      @tr.execute
      usage = calculate_usage(costs_default_penalty, -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "pt -> bus")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "pt -> pt")

      old_penalty = get_pt_to_bus_penalty()
      set_pt_to_bus_penalty(old_penalty*2)
      @tr.execute
      set_pt_to_bus_penalty(old_penalty)

      usage = calculate_usage(costs_pt_to_bus_penalty_doubled, -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "pt -> bus")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT' ,2,1,1,1,1,5], "load"), 0.01, "pt -> pt")
    }
  end
end

#require 'test/unit/ui/console/testrunner'
#Test::Unit::UI::Console::TestRunner.run(TC_penalty, 3)
