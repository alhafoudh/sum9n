
require "rubygems"
require "activesupport"
require "active_record"
require "pp"

require "summarizer"

# ActiveRecord::Base.logger = Logger.new(STDERR)
# ActiveRecord::Base.colorize_logging = true

ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :dbfile  => ":memory:"
)

ActiveRecord::Schema.define do
  
    def job_template(table)
      table.column :job, :string
      table.column :timestamp, :datetime
      table.column :duration, :integer
    end
    
    create_table "availability" do |table|
      job_template table
    end    
  
    [:hourly, :daily, :monthly, :yearly].each do |period|
      create_table "availability_#{period}" do |table|
        job_template table
      end
    end
    
end

[:hourly, :daily, :monthly, :yearly].each do |period|
  template = <<-END
    class Availability#{period.to_s.titleize} < ActiveRecord::Base
      set_table_name "availability_#{period.to_s}"
    end
  END
  
  eval template
end

##############

class Availability < ActiveRecord::Base
  set_table_name "availability"
end

120.times do |n|
  a = Availability.new  
  a.job = "ping"
  a.timestamp = Time.parse("2009/04/01 00:05") + n.minutes
  a.duration = rand(5000)
  a.save
end

sum = Summarizer.new :average => :duration,
                     :group_by => :timestamp,
                     :model => :availability,
                     :groups => {
                       :hourly => ["%Y-%m-%d %H:00", nil],
                       :daily => ["%Y-%m-%d", :hourly],
                       :monthly => ["%Y-%m", :daily],
                       :yearly => ["%Y", :monthly]
                     }
                     
sum.records = lambda { Availability.all }

sum.summarize

[:hourly, :daily, :monthly, :yearly].each do |period|
  count = eval("Availability#{period.to_s.titleize}.count(:all)")
  template = <<-END
    puts "Availability#{period.to_s.titleize} count=#{count}"
  END
  
  eval template
end