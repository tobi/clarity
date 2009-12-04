module ProcessTree
  
  def self.kill(ppid)
    return if ppid.nil?
    all_pids = [ppid] + child_pids_of(ppid).flatten.uniq.compact
    all_pids.each do |pid|
      Process.kill('TERM',pid.to_i) rescue nil
    end
  end

  def self.child_pids_of(ppid)
    out = `ps -opid,ppid | grep #{ppid.to_s}`
    ids = out.split("\n").map {|line| $1 if line =~ /^\s*([0-9]+)\s.*/ }.compact
    ids.delete(ppid.to_s)
    if ids.empty?
      ids
    else
      ids << ids.map {|id| child_pids_of(id) }
    end
  end
  
  
end