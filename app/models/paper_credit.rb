class PaperCredit < ActiveRecord::Base

  scope :flow_zero, -> { where('flow_id > ?', 0) }

  def self.maxi
    return self.maximum('flow_id')+1
  end

  def self.new_flow(flow, new_ag)
    self.create(flow_id: flow, string_key: new_ag, flow_name: new_ag)
  end

end
