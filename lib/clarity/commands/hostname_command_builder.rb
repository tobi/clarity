class HostnameCommandBuilder

  def self.command
    `hostname`
  end

end