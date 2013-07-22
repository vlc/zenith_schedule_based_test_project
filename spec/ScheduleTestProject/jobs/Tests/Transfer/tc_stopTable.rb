require 'utils/spec/ot_test_suite'

class TC_stopTable < OtTestCase

  def setup
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
    @tr = nil
    super
  end

  def test_simple
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      # @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.scheduleAnimateLoads = true
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.execute
      usage = calculate_usage([30,28], -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [6,1,'Bus',10070,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [6,1,'PT', 10075,1,1,1,1,5], "load"), 0.01, "cheaper path")

      assert_in_delta(10,          @db.get_value('stop5_3data1', [1,1,'PT' ,10060,1,1,1,3,0,0], "boarding"),  0.01, "boardings")
      # There is some ambiguity in the next two tests, travel on line 1 runs from 60->65, then 5 min wait at stop 2, then re-board
      # line 4/5 at 70/75 respectively... so the question is which time do you use for the changing entry? alight time 65 or one of the
      # two reboard times? I'm going with re-boarding time for now... the problem should be addressed with the new structure of
      # the stop5_4data1 table [see test_stop5_4table]
      assert_in_delta(10*usage[0], @db.get_value('stop5_3data1', [2,1,'Bus',10070,1,1,1,3,0,4], "changing"),  0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_3data1', [2,1,'PT' ,10075,1,1,1,3,0,5], "changing"),  0.01, "changing 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_3data1', [4,1,'Bus',10080,1,1,1,4,0,0], "alighting"), 0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_3data1', [4,1,'PT' ,10078,1,1,1,5,0,0], "alighting"), 0.01, "changing 3->5")
    }
  end

  def test_aggregation
    assert_nothing_raised(RuntimeError) {

      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      #@tr.scheduleAnimateLoads = true
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.execute
      usage = calculate_usage([30,28], -0.1)
      assert_in_delta(10*usage[0], @db.get_value('link5_2data1', [4,1,'Bus',2,1,1,1,1,4], "load"), 0.01, "more expensive path")
      assert_in_delta(10*usage[1], @db.get_value('link5_2data1', [4,1,'PT', 2,1,1,1,1,5], "load"), 0.01, "cheaper path")

      assert_in_delta(10,          @db.get_value('stop5_3data1', [1,1,'PT' ,2,1,1,1,3,0,0], "boarding"),  0.01, "boardings")
      assert_in_delta(10*usage[0], @db.get_value('stop5_3data1', [2,1,'Bus',2,1,1,1,3,0,4], "changing"),  0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_3data1', [2,1,'PT' ,2,1,1,1,3,0,5], "changing"),  0.01, "changing 3->5")
      assert_in_delta(10*usage[0], @db.get_value('stop5_3data1', [4,1,'Bus',2,1,1,1,4,0,0], "alighting"), 0.01, "changing 3->4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_3data1', [4,1,'PT' ,2,1,1,1,5,0,0], "alighting"), 0.01, "changing 3->5")
    }
  end

  def test_stop5_2data1_table
    assert_nothing_raised(RuntimeError) {
      # schedule based properties
      @tr.scheduleStartTime = @timePeriods.first
      @tr.scheduleDurations = [5]
      # @tr.scheduleAggregateTimePeriods = { 10000..10120 => 2 }.to_a
      @tr.logitParameters  = [0.1]

      # EXECUTE!!!
      @tr.execute
      usage = calculate_usage([30,28], -0.1)
      assert_equal(3, OtQuery.execute_to_a("SELECT count(*) FROM '#{File.join($Ot.variantDirectory, 'stop5_2data1.db')}'").flatten.first, 'number of records')
      assert_in_delta(10,          @db.get_value('stop5_2data1', [1,1,'PT' ,10060,1,1,1,3,1], "firstboarding"), 0.01, "boardings")
      assert_in_delta(10*usage[0], @db.get_value('stop5_2data1', [4,1,'Bus',10080,1,1,1,4,2], "lastalighting"), 0.01, "alighting from 4")
      assert_in_delta(10*usage[1], @db.get_value('stop5_2data1', [4,1,'PT' ,10078,1,1,1,5,2], "lastalighting"), 0.01, "alighting from 5")
    }
  end

end

OtTestCaseRunner.run(__FILE__)