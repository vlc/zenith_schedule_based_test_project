require 'utils/spec/ot_test_suite'

class TC_stop5_4data1_table < OtTestCase

  def setup
    insert_stop5_4data1_table
    OtTestUtils.clearOutputTables

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
    assert_nothing_raised(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAnimateLoads = true
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.execute
      usage = calculate_usage([30,28], -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [6,1,'Bus',10070,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [6,1,'PT', 10075,1,1,1,1,5], "load"), 0.01, "cheaper path")

      assert_in_delta(10,          @db.get_value('stop5_4data1', [1,1,'PT' ,10060,1,1,1,3,0,0,1], "firstboarding"),  0.01, "boardings")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',10065,1,1,1,3,0,4,0], "changealighting"),  0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT', 10065,1,1,1,3,0,5,0], "changealighting"),  0.01, "changing 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',10070,1,1,1,3,0,4,0], "changeboarding"),  0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT' ,10075,1,1,1,3,0,5,0], "changeboarding"),  0.01, "changing 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [4,1,'Bus',10080,1,1,1,4,0,0,2], "lastalighting"), 0.01, "alighting from 4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [4,1,'PT' ,10078,1,1,1,5,0,0,2], "lastalighting"), 0.01, "alighting from 5")
      OtQuery.execute("DELETE FROM '#{File.join($Ot.variantDirectory, 'stop5_4data1.db')}'")
    }
    return

    assert_nothing_raised(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.execute
      usage = calculate_usage([30,28], -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [6,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [6,1,'PT', 2,1,1,1,1,5], "load"), 0.01, "cheaper path")

      assert_equal(5, OtQuery.execute_to_a("SELECT count(*) FROM '#{File.join($Ot.variantDirectory, 'stop5_4data1.db')}'").flatten.first, 'number of records')
      assert_in_delta(10,          @db.get_value('stop5_4data1', [1,1,'PT' ,2,1,1,1,3,0,0,1], "firstboarding"),  0.01, "boardings")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',2,1,1,1,3,0,4,0], "changealighting"),  0.01, "change alighting 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT', 2,1,1,1,3,0,5,0], "changealighting"),  0.01, "change alighting 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [2,1,'Bus',2,1,1,1,3,0,4,0], "changeboarding"),  0.01, "change boarding 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [2,1,'PT' ,2,1,1,1,3,0,5,0], "changeboarding"),  0.01, "change boarding 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_4data1', [4,1,'Bus',2,1,1,1,4,0,0,2], "lastalighting"), 0.01, "alighting from 4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_4data1', [4,1,'PT' ,2,1,1,1,5,0,0,2], "lastalighting"), 0.01, "alighting from 5")

    }
  end
end

OtTestCaseRunner.run(__FILE__)