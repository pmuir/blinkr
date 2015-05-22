class Numeric
  def duration
    rest, secs = self.divmod( 60 )  # self is the time difference t2 - t1
    rest, mins = rest.divmod( 60 )
    days, hours = rest.divmod( 24 )

    # the above can be factored out as:
    # days, hours, mins, secs = self.duration_as_arr
    #
    # this is not so great, because it could include zero values:
    # self.duration_as_arr.zip ['Days','Hours','Minutes','Seconds']).flatten.join ' '

    result = []
    result << "#{days} Days" if days > 0
    result << "#{hours} Hours" if hours > 0
    result << "#{mins} Minutes" if mins > 0
    result << "#{secs} Seconds" if secs > 0
    return result.join(' ')
  end
end