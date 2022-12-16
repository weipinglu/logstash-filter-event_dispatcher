def filter(event)
  m = event.get("message")
  # e.g. m = "level_2_tag=filter_11,event_log=(kv=)a=1,b=2,c=3,d=4,e=5"
  if m.start_with?("(")
    i = m.index(")")
    event.set("event_filter_tag", m[0..i])
    event.set("message", m[i+1..])
  end
  return [event]
end