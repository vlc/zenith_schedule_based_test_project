require 'utils/spec/ot_test_suite'
require $Ot.jobDirectory / 'ot_schedule_test_case'

class TC_stop5_4data1_table < OtScheduleTestCase

  def setup
    super
    insert_stop5_4data1_table
    @tr.load = [1,30,10,1,1,1]
    @tr.network = [30,10]
    @tr.scheduleBased = true
  end

  def teardown
    delete_stop5_4data1_table
    super
  end

  def insert_stop5_4data1_table
    empty_file = File.join($Ot.projectDirectory, 'data', 'empty_tables', 'stop5_4data1.db')
    dest_file  = File.join($Ot.variantDirectory, 'stop5_4data1.db')
    FileUtils::copy(empty_file, dest_file)
  end

  def delete_stop5_4data1_table
    filename = File.join($Ot.variantDirectory, 'stop5_4data1.db')
    File.delete(filename) if File.exist?(filename)
  end

  def test_stop5_4data
    # schedule based properties
    @tr.scheduleStartTime = @timePeriods.first
    @tr.scheduleDurations = [5]
    @tr.scheduleAnimateLoads = true
    @tr.logitParameters  = [0.1]

    # EXECUTE!!!
    @tr.execute
    usage = calculate_usage([30,28], -0.1)
    assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [6,1,'Bus',tt(70),1,1,1,1,4], "load"), 0.01, "more expensive path")
    assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [6,1,'PT', tt(75),1,1,1,1,5], "load"), 0.01, "cheaper path")

    assert_in_delta(10,          @db.get_value('stop5_4data1', [1,1,'PT' ,tt(60),1,1,1,3,0,0,1], "firstboarding"),  0.01, "boardings")
    assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',tt(65),1,1,1,3,0,4,0], "changealighting"),  0.01, "changing 3->4")
    assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT', tt(65),1,1,1,3,0,5,0], "changealighting"),  0.01, "changing 3->5")
    assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',tt(70),1,1,1,3,0,4,0], "changeboarding"),  0.01, "changing 3->4")
    assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT' ,tt(75),1,1,1,3,0,5,0], "changeboarding"),  0.01, "changing 3->5")
    assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [4,1,'Bus',tt(80),1,1,1,4,0,0,2], "lastalighting"), 0.01, "alighting from 4")
    assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [4,1,'PT' ,tt(78),1,1,1,5,0,0,2], "lastalighting"), 0.01, "alighting from 5")
    OtQuery.execute("DELETE FROM '#{File.join($Ot.variantDirectory, 'stop5_4data1.db')}'")

  end
end

OtTestCaseRunner.run(__FILE__)