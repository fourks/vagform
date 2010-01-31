require 'memory'

require 'instrument'

class Configuration
  include Memory
  attr_reader :instruments

  @@LfoWaveforms = ["Sawtooth", "Square", "Triangle", "Sample and Hold"]
  @@MemoryLayout = {
    :voice_function_combine => Memory.define(0, 1, 0x08, 0x01),
    :lfo_speed => Memory.define(1, 127, 0x09, 0x7F),
    :amd => Memory.define(1, 127, 0x0A, 0x7F),
    :pmd => Memory.define(1, 127, 0x0B, 0x7F),
    :lfo_waveform_internal => Memory.define(0, 3, 0x0C, 0x03),
    :kc_reception_mode => Memory.define(0, 2, 0x0D, 0x03),
  }

  Memory.accessors(@@MemoryLayout)

  def initialize(midi, backing_store = Array.new(0xA0, 0))
    @midi = midi
    @parameters = @@MemoryLayout
    @data = backing_store
    @instruments = (1..8).to_a.collect {|n| Instrument.new(backing_store[n * 0x20, 0x20])}
  end

  def name
    @data[0..6].inject("") { |result, char| result << char }
  end

  def name=(name)
    @data.fill(0, 0..6)
    name.each_char.each_with_index {|ch, idx| @data[idx] = ch.to_s}
  end

  def lfo_waveforms
    return @@LfoWaveforms
  end

  def lfo_waveform=(waveform)
    index_of_provided_wf = @@LfoWaveforms.index(waveform)
    raise ArgumentError, "unknown LFO waveform " + waveform if not index_of_provided_wf
    self.lfo_waveform_internal = index_of_provided_wf
  end

  def lfo_waveform
    @@LfoWaveforms[lfo_waveform_internal]
  end

  def key_code_receive_mode
    
  end
end
