
# 
# Title   Data summarization class for timestamped Active Record models
# Author  Ahmed Al Hafoudh
#

class Summarizer
  
  attr_accessor :options, :records
  
  def initialize(*options)
    @options = options.first
  end
  
  def summarize()
    model = @options[:model].to_s.titleize
    group_by = @options[:group_by]
    average = @options[:average]
    
    @options[:groups].each do |group,(period,source)|        
      
      source_class = "#{model}#{source.to_s.titleize}"
      destination_class = "#{model}#{group.to_s.titleize}"
      
      source = Kernel.const_get(source_class)
      destination = Kernel.const_get(destination_class)

      source_table = source_class.tableize.singularize
      destination_table = destination_class.tableize.singularize
          
      prev = 0
      
      milestones = source.find :all,
        :select => "distinct(strftime(\"#{period}\",#{group_by})) as _period, *",
        :group => "_period",
        :order => "#{group_by} ASC"

      if milestones.length > 1
        milestones[0..milestones.length-2].each do |src|
          candidates = source.find(:all,
            :conditions => ["#{group_by} >= ? and #{group_by} <= ?",prev,src.timestamp],
            :order => "#{group_by} ASC"
            )
          
          attrs = src.attributes
          attrs.delete "id"
          attrs.delete "_period"

          summarized = destination.create(attrs)
          summarized.timestamp = Time.parse(src._period)
          summarized.send "#{average}=", candidates.map { |c| c.duration }.sum / candidates.length
                
          summarized.save
          candidates.each { |c| c.delete }
        end          
      end
    end
  end
  
end
