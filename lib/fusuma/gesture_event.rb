module Fusuma
  # pinch or swipe or rotate event
  class GestureEvent
    def initialize(time, event, finger, directions)
      @time = time.to_f
      @event = event
      @finger = finger
      @move_x = directions[:move][:x].to_f
      @move_y = directions[:move][:y].to_f
      @zoom   = directions[:zoom].to_f
    end
    attr_reader :time, :event, :finger,
                :move_x, :move_y, :zoom

    class << self
      def initialize_by(line, device_names)
        return if device_names.none? do |device_name|
          line.to_s =~ /^\s?#{device_name}/
        end
        return if line.to_s =~ /_BEGIN/
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH|POINTER_AXIS/
        time, event, finger, directions = gesture_event_arguments(line)
        MultiLogger.debug(time: time, event: event,
                          finger: finger, directions: directions)
        GestureEvent.new(time, event, finger, directions)
      end

      private

      def gesture_event_arguments(libinput_line)
        event, time, finger, other = parse_libinput(libinput_line)
        puts "===============", other
        move_x, move_y, zoom = parse_finger_directions(other)
        directions = { move: { x: move_x, y: move_y }, zoom: zoom }
        [time, event, finger, directions]
      end

      def parse_libinput(line)
        _device, event, time, other = line.strip.split(nil, 4)
        if event === 'POINTER_AXIS'
          finger = 2
          move_x, move_y = other.gsub('horiz','').gsub('vert', '').gsub('*','').gsub('(finger)','').split
          other = "#{move_y}/#{move_x}"
          if move_x === '0.00' && move_y === '0.00'
            event = 'GESTURE_SWIPE_END'
          else
            event = 'GESTURE_SWIPE_UPDATE'
          end
        else
          finger, other = other.split(nil, 2)
        end
        [event, time, finger, other]
      end

      def parse_finger_directions(line)
        return [] if line.nil?
        move_x, move_y, _, _, _, zoom = line.tr('/|(|)', ' ').split
        [move_x, move_y, zoom]
      end
    end
  end
end
