[![Build Status](https://secure.travis-ci.org/savonarola/pulse-meter.png)](http://travis-ci.org/savonarola/pulse-meter)

# PulseMeter

PulseMeter is a gem for fast and convenient realtime aggregating of software internal stats through Redis.

## Features

PulseMeter is designed to provide the following features:

 * Simple deployment. The only infrastructure resource you are required to have is Redis.

 * Low resource consumption. Since different kinds of events are aggregated in Redis,
   you are as light and fast as Redis is.
   Event data is stored in constant space and expires over time.

 * Focus on the client. To start gathering some metrics, you should only modify your client: create a sensor object
   and send events to it. All aggregated data can be accessed immediately without any
   sort of "server reconfiguration"

## Concept

The fundamental concept of PulseMeter is *sensor*. Sensor is some named piece of data in Redis which
can be updated through client side objects associated with this data. The semantics of the data can be
different: some counter, value, series of values, etc. There is no need to care about explicit creation this data:
one just creates a client object and writes data to it, e.g.

    PulseMeter.redis = Redis.new
    sensor = PulseMeter::Sensor::Counter.new :my_counter
    sensor.event(5)
    ...
    sensor.event(3)

After that the value associated with the counter is immediately available (through CLI, for example). Any other
client can access the associated counter by creating object with the same redis db and sensor name.

Sensors can be divided into two large groups.

### Static sensors

These are just single values which can be read by CLI, e.g. some counter or some value
representing current state of a resource (current free memory amount, current la etc.). Currently, the
following static sensors are available:

  * Counter
  * Hashed Counter
  * Indicator

They have no web visualisation interface and they are assumed to be used by external visualisation tools.


### Timeline sensors

These sensors are series of values, one value for each consequent time interval. They
are available by CLI and have web visualisation interface. Examples of such sensors include: count of
requests to some resource per hour, the longest request to a database per minute, etc.

The following timeline sensors are available:

  * Average value
  * Counter
  * Hashed counter
  * Max value
  * Min value
  * Median value
  * Percentile

There are several caveats with timeline sensors:

  * The value of a sensor for the last time interval (which is not finished yet) is often not very useful.
    When building a visualisation you may choose to display the last value or not.
  * For some sensors (currently Median and Percentile) considerable amount of data should be stored for a
    particular interval to obtain value for this interval. So it is a good idea to schedule
    <tt>pulse-meter reduce</tt>
    command on a regular basis. This command reduces the stored data for passed intervals to single values,
    so that they do not consume storage space.

## Usage

Just create sensor objects and write data. Some examples below.

    require 'pulse-meter'
    PulseMeter.redis = Redis.new

    # static sensor examples

    counter = PulseMeter::Sensor::Counter.new :my_counter
    counter.event(1)
    counter.event(2)
    puts counter.value
    # prints
    # 3

    indicator = PulseMeter::Sensor::Indicator.new :my_value
    indicator.event(3.14)
    indicator.event(2.71)
    puts indicator.value
    # prints
    # 2.71

    hashed_counter = PulseMeter::Sensor::HashedCounter.new :my_h_counter
    hashed_counter.event(:x => 1)
    hashed_counter.event(:y => 5)
    hashed_counter.event(:y => 1)
    p hashed_counter.value
    # prints
    # {"x"=>1, "y"=>6}

    # timeline sensor examples

    requests_per_minute = PulseMeter::Sensor::Timelined::Counter.new(:my_t_counter,
      :interval => 60,         # count for each minute
      :ttl => 24 * 60 * 60     # keep data one day
    )
    requests_per_minute.event(1)
    requests_per_minute.event(1)
    sleep(60)
    requests_per_minute.event(1)
    requests_per_minute.timeline(2 * 60).each do |v|
      puts "#{v.start_time}: #{v.value}"
    end
    # prints somewhat like
    # 2012-05-24 11:06:00 +0400: 2
    # 2012-05-24 11:07:00 +0400: 1

    max_per_minute = PulseMeter::Sensor::Timelined::Max.new(:my_t_max,
      :interval => 60,         # max for each minute
      :ttl => 24 * 60 * 60     # keep data one day
    )
    max_per_minute.event(3)
    max_per_minute.event(1)
    max_per_minute.event(2)
    sleep(60)
    max_per_minute.event(5)
    max_per_minute.event(7)
    max_per_minute.event(6)
    max_per_minute.timeline(2 * 60).each do |v|
      puts "#{v.start_time}: #{v.value}"
    end
    # prints somewhat like
    # 2012-05-24 11:07:00 +0400: 3.0
    # 2012-05-24 11:08:00 +0400: 7.0

## Installation

Add this line to your application's Gemfile:

    gem 'pulse-meter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pulse-meter


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
