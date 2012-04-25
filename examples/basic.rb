require 'pulse-meter/visualizer'

visualizer = PulseMeter::Visualizer.draw do
  
  title "My Gauges"
  
  redis 'redis://192.168.1.3:12'

  chart :convertion do
    sensor :adv_clicks, color: :green
    sensor :adv_shows, color: :red
  end

  redis 'redis://192.168.1.1:12'

  pie :agents do
    sensor :agent_ie
    sensor :agent_chrome
    sensor :agent_ff
    sensor :agent_other
  end

  chart :rph_total, sensor: :rph_total
  chart :rph_main_page, sensor: :rph_main_page
  chart :request_time_p95_hour

  pie :success_vs_fail_total_hourly do
    sensor :success_total_hourly
    sensor :fail_total_hourly
  end

  dashboard do
    chart :convertion, width: 66
    pie :agents, width: 34
  end

  page "Request stats" do
    chart :rph_total
    chart :rph_main_page
    chart :request_time_p99_hour
    pie :success_vs_fail_total_hourly
  end

  redraw_interval 10

end

require 'yaml'
puts visualizer.to_yaml
