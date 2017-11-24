#
# data.rb
#
# How our data is stored
#

require('json');

class DataHandler
	def getpath(key)
		"./data/#{key}.json"
	end
	def [](key)
		if @files.key?key
			@files[key];
		else
			file=getpath(key)
			if File.exist?file
				@files[key]=JSON.parse(File.read(file));
			else
				nil
			end
		end
	end
	def []=(key,value)
		@files[key]=value;
	end
	def initialize
		if !Dir.exist?'./data'
			Dir.mkdir('./data');
		end

		@files={};
	end
	def save
		@files.each{|file,data|
			puts("#{file}=>#{data}");
			File.write(getpath(file),data.to_json);
		}
	end
end

$data=DataHandler.new;

at_exit{
	$data.save;
}
