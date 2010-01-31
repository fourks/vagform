require 'midi_lex'
require 'yfb01/midi_communicator'

class FB01Connector < NSViewController
  attr_writer :editor, :view_parent, :channel_selector

  def midi_device_selected(sender)
    midi.open(sender.titleOfSelectedItem)
  end

  def midi_devices
    midi.devices
  end

  def channels
    midi.channels
  end

  def midi
    @editor.communicator
  end

  def channel_selected(sender)
    midi.system_channel = sender.indexOfSelectedItem.to_i + 1
  end
  
  def selected_channel_label
    midi.system_channel.to_s
  end

  def awakeFromNib
    puts "view = #{self.view}"
    puts "view2 = #{@view_parent}"
    @channel_selector.setSegmentCount(channels.size)
    channels.each_with_index do |ch, idx|
      @channel_selector.setLabel(ch.to_s, forSegment:idx)
      @channel_selector.setWidth(ch.to_s.length == 2 ? 22 : 13, forSegment:idx)
    end
    @view_parent.addSubview(view)
    
#    available_devices = @midi.devices
#    @midi.open(available_devices[0]) if available_devices.length > 0
#    available_devices
  rescue => e
    puts "Error " + e.message
  end
end
