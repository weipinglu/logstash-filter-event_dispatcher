def filter(event)
  m = event.get("message")
  if m.start_with?("level_1_tag=")
    i1 = "level_1_tag=".length
    i2 = m.index(",")
    event.set("event_filter_tag", m[i1..i2-1])
    m1 = m[i2+1..]
    if m1.start_with?("event_log=")
      event.set("message", m1["event_log=".length..])
    end
  end
  return [event]
end