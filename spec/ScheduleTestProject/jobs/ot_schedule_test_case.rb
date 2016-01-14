class OtScheduleTestCase < OtTestCase

  # This is a convenience alias for when we are checking link5 outputs
  alias :tt :get_timetable_offset_time

  def setup
    clearOutputTables

    @all_time_to_single_period_aggregation = { get_timetable_offset_time(0)..get_timetable_offset_time(1440) => 2 }.to_a
    @timePeriods = [get_timetable_offset_time(400)]
    @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], [[1,2,10]]) }

    @tr                           = OtTransit.new(:freshly_built)
    @tr.loadMatricesFromSkimCube  = true
    @tr.odMatrix                  = [1, 30, @timePeriods, 1, 1, 1]
    @tr.scheduleBased             = true
    @tr.scheduleDynamicTimes      = [10000, 1, 0, 1]

    super
  end

end