require("io/console");

# A basic way to gather user input. You can just require('input') and
# then do $input.listen(
#	'key'->{
#		action();
#	}
# )

class Input
	# Multiple rules at once in the form of a dictionary, for ease of use.
	def listen(keys)
		keys.each{ |l,k|
			self.rule(l,k);
		}
	end
	def rule(key,action)
		key=key.to_sym;

		if @rules.key? key
			rule=@rules[key];

			# TODO: Why would this ever happen? Rule is supposed to be an array.
			if (rule.respond_to? :call)
				@rules[key]=rule=[rule];
			end

			rule.push(action);
		else
			@rules[key]=[action];
		end
	end
	def onkey(action)
		@onkey.push(action);
	end
	def initialize
		# Exit function, because we override CTRL-C. q is also mapped to exit for now.
		x = ->{
			# If we are run by the main program, close it, otherwise just do an exit.
			if $main
				$main.close('user signal');
			else
				exit;
			end
		};

		@onkey=[];
		@rules={
			"\u0003":x
		};

		# No echo to output
		STDIN.echo = false;
		STDIN.raw!

		Thread.new{
			# Keypress check
			while true
				char = STDIN.getch;

				# Escape characters
				if (char=="\u001b")
					char+=STDIN.getch+STDIN.getch;
				end

				key=char;

				begin
					@onkey.each{|ac|
						ac.call(key);
					}
				rescue StandardError => e
					puts(e);
				end

				begin

					key=key.to_sym;
					if @rules.key? key
						rule=@rules[key];

						# Check if rule is iterable
						if (rule.respond_to? :each)
							rule.each{ |f|
								f.call();
							}
							# Check if it's callable
						elsif (rule.respond_to? :call)
							rule.call();
						else
						end
					end
				rescue StandardError => e
					# we don't reraise because the input thread can't crash in case the listener has an error
					puts(e);
				end
			end
		}
	end

	def close
		# Remember to set these back to their default values on close.
		STDIN.echo = true;
		STDIN.cooked!
	end
end

$input=Input.new();

at_exit{
	# Remember to close gracefully.
	$input.close();
}
