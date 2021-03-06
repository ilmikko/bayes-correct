#
# errortracker.rb
#
# This module keeps track of errors the user makes, with the help of our context sentence.
# Corrections are stored in the 'corrections' dictionary.
#

require_relative('./data.rb');

# initialize corrections in data
# There might be a variety of corrections to different incorrect words.
# the corrections are of format:
# {
#		"incorrect":{
#			"correction":(int frequency)
#		}
# }
# Roughly translating to:
# The word 'incorrect' has a correction 'correction' with a frequency of `frequency`.
#
$data['corrections']={} if $data['corrections'].nil?;

class ErrorTracker
	def status
		"[Tracking:#{@tracking ? 1 : 0}][i:#{@incorrects.length}][c:#{@corrections.keys.length}]";
	end
	def track(incorrect)
		log("EE: #{incorrect}");
		@incorrects.push(incorrect[0..-1]);
		@tracking=true;
	end
	def correct(word)
		@incorrects.each{|incorrect|
			next if incorrect==word;

			# TODO: Correct with levdist
			# Corrections that go 'a => amoebashandbag'
			# Because that is technically correct
			# but we don't want those.

			@corrections[incorrect]={} if !@corrections.key?incorrect;
			@corrections[incorrect][word]=0 if !@corrections[incorrect].key?word;
			@corrections[incorrect][word]+=1;
			log("EC: #{incorrect} => #{word}");
		}
		reset;
	end
	def tracking?
		@tracking;
	end
	def reset
		@tracking=false;
		@incorrects=[];
	end
	def initialize
		@corrections=$data['corrections'];
		reset;
	end
end
