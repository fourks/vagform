#  .
# VAGFORM, a MIDI Synth Editor
# Copyright (C) 2010  M Norrby
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
require 'memory'
require 'timeout'
require 'observable'
require 'pmd_controllers'
require 'voice'

class Instrument
  include Memory
  include Timeout
  include Observable
  include PmdControllers

  attr_writer :instrument_no
  attr_reader :comm, :voice

  @@Tones = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "H"]
  @@Keys = (-2..8).to_a.collect do |num| @@Tones.collect {|tone| "#{tone}#{num}" } end.flatten[0..127]

  @@MemoryLayout = {
    :notes => Memory.define(0, 8, 0x00, 0x0F),
    :midi_channel_internal => Memory.define(0, 15, 0x01, 0x0F),
    :upper_key_limit_int => Memory.define(0, @@Keys.length - 1, 0x02, 0x7F),
    :lower_key_limit_int => Memory.define(0, @@Keys.length - 1, 0x03, 0x7F),
    :voice_bank_no => Memory.define(0, 6, 0x04, 0x07),
    :voice_no => Memory.define(0, 47, 0x05, 0x7F),
    :detune => Memory.define(0, 127, 0x06, 0x7F),
    :octave_transpose_internal => Memory.define(0, 4, 0x07, 0x07),
    :output_level => Memory.define(0, 127, 0x08, 0x7F),
    :pan_internal => Memory.define(0, 127, 0x09, 0x7F),
    :lfo_enable => Memory.define(0, 1, 0x0A, 0x01),
    :portamento_time => Memory.define(0, 127, 0x0B, 0x7F),
    :pitchbender_range => Memory.define(0, 12, 0x0C, 0x0F),
    :mono => Memory.define(0, 1, 0x0D, 0x01),
    :pmd_controller_no => Memory.define(0, 4, 0x0E, 0x07)
  }

  Memory.accessors(@@MemoryLayout)

  def self.null
    return @null if @null
    puts "creating new null object"
    @null = Instrument.new(nil)
  end

  def initialize(midi, backing_store = Array.new(0x10, 0))
    @parameters = @@MemoryLayout
    @comm = midi
    @data = backing_store
    @voice = Voice.new(midi, self)
  end

  def replace_memory(new_bulk)
    @data = new_bulk
    notify_observers
  end

  def read_voice_data_from_fb01(&block)
    request = [0x43, 0x75, 0x00 + @comm.system_channel - 1, 0x28 + no - 1, 0x00, 0x00]
    raw_response = [0xF0, 0x43, 0x75, 0x00 + @comm.system_channel - 1, 0x08 + no - 1, 0x00, 0x00]
    data = @comm.receive_interleaved_dump(request, raw_response)
    @voice.replace_memory(data) if data
  rescue =>e
    puts "timeout? #{e}"
  end

  def no
    @instrument_no
  end

  def send_to_fb01(pos, data)
    channel_index = @comm.system_channel - 1
    instrument_index = no - 1
    @comm.sysex([0x43, 0x75, channel_index, 0x18 + instrument_index, pos, data])
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

  def pan
    self.pan_internal - 64
  end

  def pan=(pan)
    self.pan_internal = pan + 64
  end

  def min_pan
    self.min_pan_internal - 64
  end

  def max_pan
    self.max_pan_internal - 64
  end

  def octave_transpose
    self.octave_transpose_internal - 2
  end

  def octave_transpose=(transpose)
    self.octave_transpose_internal = transpose + 2
  end

  def min_octave_transpose
    self.min_octave_transpose_internal - 2
  end

  def max_octave_transpose
    self.max_octave_transpose_internal - 2
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

  def max_lower_key_limit
    self.max_lower_key_limit_int
  end

  def min_lower_key_limit
    self.min_lower_key_limit_int
  end

  def max_upper_key_limit
    self.max_upper_key_limit_int
  end

  def min_upper_key_limit
    self.min_upper_key_limit_int
  end

  def upper_key_limit
    self.upper_key_limit_int
  end

  def upper_key_limit=(limit)
    self.upper_key_limit_int = limit
    self.lower_key_limit_int = limit if lower_key_limit >= limit
  end

  def lower_key_limit
    self.lower_key_limit_int
  end

  def lower_key_limit=(limit)
    self.lower_key_limit_int = limit
    self.upper_key_limit_int = limit if upper_key_limit <= limit
  end

  def upper_key_limit_name
    @@Keys[upper_key_limit]
  end

  def upper_key_limit_name=(name)
    index = @@Keys.index(name)
    raise "There is no \"#{name}\" key. Only #{@@Keys.values}" if not index
    self.upper_key_limit = index
  end

  def midi_channels
    (min_midi_channel..max_midi_channel).to_a.collect do |c|
      "Ch #{c}"
    end
  end

  def voices
    (min_voice_no..max_voice_no).to_a.collect do |v|
      "Voice #{v + 1}"
    end
  end

  def voice_banks
    (min_voice_bank_no..max_voice_bank_no).to_a.collect do |b|
      "Bank #{b + 1}"
    end
  end

  def keys
    @@Keys
  end
end
