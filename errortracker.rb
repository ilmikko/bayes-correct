#
# errortracker.rb
#
# This module keeps track of errors the user makes, with the help of our context sentence.
# Corrections are stored in the 'corrections' dictionary.
#
class ErrorTracker
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

			@corrections[incorrect]=word;
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
		@corrections={};
		reset;
	end
end
