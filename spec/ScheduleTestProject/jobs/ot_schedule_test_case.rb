class OtScheduleTestCase < OtTestCase

  # This is a convenience alias for when we are checking link5 outputs
  alias :t :get_timetable_offset_time

  def setup
    clearOutputTables

    @all_time_to_single_period_aggregation = { get_timetable_offset_time(0)..get_timetable_offset_time(110) => 2 }.to_a
    @timePeriods = [get_timetable_offset_time(50)]
    @timePeriods.each { |t| create_matrix([1,30,t,1,1,1], [[1,2,10]]) }

    @tr                           = OtTransit.new
    @tr.loadMatricesFromSkimCube  = true
    @tr.odMatrix                  = [1,30,@timePeriods,1,1,1]
    @tr.scheduleBased             = true

    super
  end

end