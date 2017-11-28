#
# inputlistener.rb
#
# Listens to raw keypresses and tries to interpret them as text modification commands. Everything else is ignored.
# The input is then forwarded to context sentence, which tries to interpret text specifically.
#

require_relative('./contextsentence.rb');
require_relative('./cumulavg.rb');

class InputListener
	@@contextsentence=ContextSentence.new;
	def status
		def anim
			@anim="/-\\|".split(//) if !@anim;
			@anim.push(@anim.shift)[0];
		end
		print("\e[2J\e[;H");
		print("[#{anim} InputListener #{[@modshift,@modctrl,@modalt].map{|x| x ? '1' : '0'}.join(' ')}]\r\n");
		print("Last key: #{@key}\r\n");
		print("Key avg: #{@keyaverage} (#{@keyerror}%)\r\n");
		print(@@contextsentence.status);
		print("\r\n[Log]\r\n");
		print($log.last(10).join("\r\n"));
	end
	def up(key)
		# Reset modifiers
		if key=='SHIFT'
			@modshift=false;
		elsif key=='CTRL'
			@modctrl=false;
		elsif key=='ALT'
			@modalt=false;
		end
	end
	def hold(key)
		# Ignore modifier hold.
		# If holding other stuff we lose track of everything
		# and we need to reset the cs.
		if key=='SHIFT' || key=='CTRL' || key=='ALT'
		else
			@@contextsentence.reset;
		end
	end
	def down(key)
		# What do when a key is pressed?
		# Our mission is to try and fill out words
		# When we can identify which word we're working on
		# then we can start looking at corrections to those words.
		# And finally when we have the corrections to those words, we can start looking at actually correcting the user's typos.
		# Do not discriminate just to A-Z, because we have keys like ; and ' that get used in other languages.
		# So basically everything else is a word except
		#
		# BS
		# ENTER
		# SPACE
		# ESC
		# ...

		# Get timestamp for keystroke
		timestamp=Time.now;

		if !@lastkeystroke.nil?
			# Get time delta
			delta=timestamp-@lastkeystroke;
			
			# Are we typing?
			@keyaverage=CumulativeAverage.new(delta) if @keyaverage.nil?;

			@keyerror=(@keyaverage-delta).abs/@keyaverage;

			@@contextsentence.reset if @keyerror>10; # Reset if there has been a disrepancy in typing

			@keyaverage.update(delta);
		end

		## TODO: Divide this into its own module
		ignore=['ESC','BS','TAB','ENTER','L CTRL','L SHIFT','R SHIFT','L ALT','SPACE','CAPS LOCK','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','NUM LOCK','SCROLL LOCK','NUM INS','NUM DEL','R ENTER','R CTRL','PRT SCR','R ALT','HOME','UP','PGUP','LEFT','RIGHT','END','DOWN','PGDN','INS','DEL','PAUSE','><'];
		resetters=['UP','DOWN','TAB','ENTER','ESC'];
		breakers=['SPACE','ENTER']
		# TODO: Support some modifier bunches like CTRL+A BS (select all backspace) or CTRL+LEFT (move word left)
		# CTRL+BS (remove word)

		# Check modifiers first.
		# These don't do anything on their own, just modify sheit.
		if key=='SHIFT'
			@modshift=true;
		elsif key=='ALT'
			@modalt=true;
		elsif key=='CTRL'
			@modctrl=true;
		elsif breakers.include?key
			# Space is a special key
			# Break words
			@@contextsentence.break;
		elsif key=='BS'
			# Backspace is a special key
			# Correct words, move between words
			if @modctrl;
				@@contextsentence.reset;
			else
				@@contextsentence.delete;
			end
		elsif key=='DEL'
			# Delete is equivalent to RIGHT BS
			if @modctrl;
				@@contextsentence.reset;
			else
				# Only if we can move right though!
				if @@contextsentence.move(1)
					@@contextsentence.delete;
				end
			end
		elsif key=='LEFT' || key=='RIGHT'
			# We can still move around our sentence and try to correct words we know in this context
			if @modctrl
				# move a word
				if key=='LEFT'
					@@contextsentence.moveWord(-1);
				else
					@@contextsentence.moveWord(1);
				end
			else
				# move a char
				if key=='LEFT'
					# Left
					@@contextsentence.move(-1);
				else
					# Right
					@@contextsentence.move(1);
				end
			end
		elsif resetters.include?key
			# Reset our context sentence
			@@contextsentence.reset;
		elsif !ignore.include?key
			if !@modalt && !@modctrl
				@@contextsentence.add(key);
			else
				# Special cases
				if @modctrl && key=='A'
					# Ctrl-A
					@@contextsentence.reset;
				end
			end
		end


		@lastkeystroke=timestamp;
		@key=key;
	end
	def initialize
		@modctrl=false;
		@modalt=false;
		@modshift=false;

		@lastkeystroke=nil;
		status();
	end
end
