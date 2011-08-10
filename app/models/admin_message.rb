class AdminMessage < DaText
  
  def self.text(id)
    msg = AdminMessage.find_by_guid(id)
    if msg
      msg.text
    else
      nil
    end
  end
  
end