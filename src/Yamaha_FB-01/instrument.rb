# -*- coding: iso-8859-1 -*-
class Instrument

  attr_writer :comm, :instrument_no

  @@Tones = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "H"]
  @@Keys = (-2..8).to_a.collect do |num| @@Tones.collect {|tone| "#{tone}#{num}" } end.flatten[0..127]

  def self.define(min, max, pos, mask)
    {:min => min, :max => max, :pos => pos, :mask => mask}
  end

  @@defs = {
    :notes => define(0, 8, 0x00, 0x0F),
    :midi_channel_internal => define(0, 15, 0x01, 0x0F),
    :upper_key_limit => define(0, @@Keys.length - 1, 0x02, 0x7F),
    :lower_key_limit => define(0, @@Keys.length - 1, 0x03, 0x7F),
    :voice_bank_no => define(0, 6, 0x04, 0x07),
    :voice_no => define(0, 47, 0x05, 0x7F),
    :detune => define(0, 127, 0x06, 0x7F),
    :octave_transpose_internal => define(0, 4, 0x07, 0x07),
    :output_level => define(0, 127, 0x08, 0x7F),
    :pan_internal => define(0, 127, 0x09, 0x7F),
    :lfo_enable => define(0, 1, 0x0A, 0x01),
    :portamento_time => define(0, 127, 0x0B, 0x7F),
    :pitchbender_range => define(0, 12, 0x0C, 0x0F),
    :mono => define(0, 1, 0x0D, 0x01),
    :pmd_controller_internal => define(0, 4, 0x0E, 0x07)
  }

  @@PmdControllers = ["Not assigned", "After touch", "Modulation wheel", "Breath controller", "Foot controller"]
  @@defs.each_key do |key|
    define_method key do
      fetch(key)
    end

    define_method "#{key}=".to_sym do |value|
      # does not shift down if mask is to the left in a work
      lower_bound = @@defs[key][:min] 
      upper_bound = @@defs[key][:max] 
      if value < lower_bound or value > upper_bound
        raise "#{key} must be in the interval [#{lower_bound}..#{upper_bound}]"
      end
      @data[pos(key)] = (@data[pos(key)] & ~mask(key)) | value
      send_to_fb01(pos(key), @data[pos(key)]) if @comm
    end

    define_method "min_#{key}".to_sym do
      @@defs[key][:min]
    end

    define_method "max_#{key}".to_sym do
      @@defs[key][:max]
    end
  end

  def initialize(backing_store = Array.new(0x10, 0))
    @data = backing_store
    @min_notes = 0
    @max_notes = 8
    @min_output_level = 0
    @max_output_level = 127
  end

  def no
    @instrument_no
  end

  def send_to_fb01(pos, data)
    channel_index = @comm.system_channel - 1
    instrument_index = @instrument_no - 1
    @comm.sysex([0x43, 0x75, channel_index, 0x18 + instrument_index, pos, data])
  end

  def mask(symbol)
    @@defs[symbol][:mask]
  end

  def pos(symbol)
    @@defs[symbol][:pos]
  end

  def fetch(parameter)
    @data[pos(parameter)] & mask(parameter)
  end

  def midi_channel
    self.midi_channel_internal + 1
  end

  def midi_channel=(ch)
    self.midi_channel_internal = ch - 1
  end

  def min_midi_channel
    self.min_midi_channel_internal + 1
  end

  def max_midi_channel
    self.max_midi_channel_internal + 1
  end

  def octave_transpose
    self.octave_transpose_internal - 2
  end

  def min_octave_transpose
    self.min_octave_transpose_internal + 1
  end

  def max_octave_transpose
    self.max_octave_transpose_internal + 1
  end

  def pmd_controller
    @@PmdControllers[pmd_controller_internal]
  end

  def pmd_controller=(controller_name)
    if not @@PmdControllers.index(controller_name)
      raise "There is no \"#{controller_name}\" controller. Only #{@@PmdControllers.values}"
    end
    controller_num = @@PmdControllers.key(controller_name)
  end

  def lower_key_limit_name
    @@Keys[lower_key_limit]
  end

  def lower_key_limit_name=(name)
    index = @@Keys.index(name)
    raise "There is no \"#{name}\" key. Only #{@@Keys.values}" if not index
    self.lower_key_limit = index
  end

  def key_to_number(key)
    @@Keys.index(key)
  end

  def upper_key_limit_name
    @@Keys[upper_key_limit]
  end

  def upper_key_limit_name=(name)
    index = @@Keys.index(name)
    raise "There is no \"#{name}\" key. Only #{@@Keys.values}" if not index
    self.upper_key_limit = index
  end

  def keys
    @@Keys
  end
end
