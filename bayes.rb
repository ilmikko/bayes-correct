# 
# Bayesian reasoning and 'smart' error correction
#
# I was an idiot.
#
# This program has two functionalities:
#
# -> Correcting typos
# -> Suggesting words (not really that interesting)

require('json');

def levDist(str1,str2)
	d = [];
	m = str1.length;
	n = str2.length;

	for i in 0..m
		d[i]=[];
		for j in 0..n
			d[i][j]=0;
		end
	end

	for i in 0..m
		d[i][0]=i+1;
	end

	for j in 0..n
		d[0][j]=j+1;
	end

	for i in 0...m
		for j in 0...n
			if str1[i+1]==str2[j+1]
				cost=0;
			else
				cost=1;
			end

			d[i+1][j+1]=[
				d[i][j+1]+1,
				d[i+1][j]+1,
				d[i][j]+cost
			].min
		end
	end

	return d[m][n];
end

$log=[];
def log(str)
	$log.push(str);
end

class CumulativeAverage
	def update(value)
		@values.shift;
		@values.push(value);
		@value=@values.inject(:+)/@values.length.to_f;
	end

	def /(number) @value/number; end
	def *(number) @value*number; end
	def +(number) @value+number; end
	def -(number) @value-number; end

	def coerce(other)
		if other.is_a? Float
			[other,to_f]
		elsif other.is_a? Integer
			[other,to_i]
		else
			raise TypeError;
		end
	end

	def inspect
		@value.to_s
	end

	def to_i
		@value.to_i
	end
	def to_f
		@value.to_f
	end
	def to_s
		@value.to_s
		#@values.join(' ')
	end

	def initialize(value,max:10)
		@value=value;
		@values=[value]*max;
	end
end

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

class Dictionary
	@@punctuation='1/,.'; # 1=>!, /=>?
	def add(word)
		word=strip(word);
		return if !valid? word;
		log("D+#{word}");
		@corpus[word]=0 if !@corpus.key?word;
		@corpus[word]+=1;
	end
	def remove(word)
		word=strip(word);
		return if word.empty?;
		log("D-#{word}");
		@corpus[word]=0 if !@corpus.key?word;
		@corpus[word]-=1;
	end
	def strip(word)
		return word.strip.gsub(/[#{@@punctuation}]$/,'');
	end
	def valid?(word)
		return false if !word.is_a? String;
		return false if word.empty?;
		return false if word.length<2; # Don't care about 'a' or 'i' as they literally cannot be typoed.
		return true;
	end
	def initialize
		@corpus={};
	end
end

class ContextSentence
	@@dictionary=Dictionary.new;
	@@errortracker=ErrorTracker.new;
	def currentword; @sentence[@cursor[0]]; end
	def previousword; @sentence[@cursor[0]-1]; end
	def nextword; @sentence[@cursor[0]+1]; end
	def status
		print("Context cursor: #{@cursor}\r\n");

		word = currentword[0..-1] << " ";
		if word.length>1
			# display cursor in word
			word.insert(@cursor[1]+1,"\e[m");
			word.insert(@cursor[1],"\e[7m");
		end

		print("Context word: #{word}\r\n");
		print("Context sentence: #{@sentence}\r\n");
	end
	def add(key)
		@erasing=false;
		# We're typing again

		if @cursor[1]!=currentword.length
			# Correction
			if !@@errortracker.tracking?
				@@errortracker.track(currentword);
			end

			@sentence[@cursor[0]].insert(@cursor[1],key);
		else
			# Typing
			@sentence[@cursor[0]]+=key;
		end
		@cursor[1]+=1;
	end
	def break
		# If we are actually breaking the word, remove the word from the dictionary
		if !currentword.empty?
			if @cursor[1]<currentword.length
				# Remove the word
				@@dictionary.remove(currentword);
			else
				# Typing streak, add this word
				finalize
			end
		end

		# Split the word where the cursor is.
		a=currentword[0...@cursor[1]];
		b=currentword[@cursor[1]..-1];

		# Insert the bits as their own ones
		@sentence[@cursor[0]]=a;
		@sentence.insert(@cursor[0]+1,b);

		@cursor[0]+=1;
		@cursor[1]=0;
	end
	def delete
		if @cursor[1]==0
			# Cursor at the start of the word, clear error tracking

			if @cursor[0]!=0
				# Join previous word and current word into one
				# Remove both of them from the dictionary
				@@dictionary.remove(currentword);
				@@dictionary.remove(previousword);

				@cursor[0]-=1;

				@cursor[1]=currentword.length;
				@sentence[@cursor[0]]+=nextword; # Concatenate the next word into current word
				@sentence.delete_at(@cursor[0]+1); # Delete the next word

				if @@errortracker.tracking?
					@@errortracker.reset;
					@@errortracker.track(currentword);
				end
			else
				@@errortracker.reset;
			end
		else
			# Consider the case:
			#
			# I like thi s p
			# corrected to
			# I like this p
			# Should yield a result
			# thi=>this
			# But instead yields
			# s=>this
			#
			# Regular deletion, error tracking
			if !@erasing
				# We don't want to track after every single backspace erase. Hence the erasing variable.
				# There can be multiple corrections to a word though.
				@erasing=true;
				@@errortracker.track(currentword); 
			end

			erased=@sentence[@cursor[0]].slice!(@cursor[1]-1);
			@cursor[1]-=1;
		end
	end
	def finalize
		@@dictionary.add(currentword);
		if @@errortracker.tracking?
			# Add correction
			@@errortracker.correct(currentword);
		end
	end
	def moveWord(words)
		return if (words==0);

		finalize;

		# Set little cursor
		if words>0
			# Going right, always at the end
			# If we're not at the end, go to the end first
			if @cursor[1]!=currentword.length;
				@cursor[1]=currentword.length;
				return;
			elsif nextword
				@cursor[1]=nextword.length;
			else
				@cursor[1]=currentword.length;
			end
		else
			# Going left, always at the start
			# If we're not at the start, go to the start first
			if @cursor[1]!=0;
				@cursor[1]=0;
				return;
			else
				@cursor[1]=0;
			end
		end

		@cursor[0]+=words;

		max=@sentence.length-1;
		
		# Clamp
		@cursor[0]=0 if @cursor[0]<0;
		@cursor[0]=max if @cursor[0]>max;
	end
	def move(chars)
		return false if (chars==0);
		if chars>0
			max=@sentence[@cursor[0]].length;
			if @cursor[1]==max
				# Hop to next word if it exists
				max=@sentence.length-1;
				if @cursor[0]!=max
					finalize;
					@cursor[0]+=1;
					@cursor[1]=0;
					return true;
				else
					return false;
				end
			else
				@cursor[1]+=1;
				return true;
			end
		else
			if @cursor[1]==0
				# Hop to the word before if it exists
				if @cursor[0]!=0
					finalize;
					@cursor[0]-=1;
					@cursor[1]=currentword.length;
					return true;
				else
					return false;
				end
			else
				@cursor[1]-=1;
				return true;
			end
		end
	end
	def reset
		@@errortracker.reset;
		@sentence.clear;
		@sentence.push('');
		@cursor=[0,0];
		@erasing=false;
	end
	def initialize
		@sentence=[];
		reset;
	end
end

class InputListener
	@@contextsentence=ContextSentence.new;
	def cs
		@@contextsentence;
	end
	def status
		def anim
			@anim="/-\\|".split(//) if !@anim;
			@anim.push(@anim.shift)[0];
		end
		print("\e[2J\e[;H");
		print("[#{anim} InputListener #{[@modshift,@modctrl,@modalt].map{|x| x ? '1' : '0'}.join(' ')}]\r\n");
		print("Last key: #{@key}\r\n");
		print("Key avg: #{@keyaverage} (#{@keyerror}%)\r\n");
		@@contextsentence.status;
		print("[Log]\r\n");
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
		resetters=['UP','DOWN','ENTER','ESC'];
		breakers=['SPACE','TAB','ENTER']
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

# Try to read an input stream first and get it to print out on stdout.

# TODO: ruby input stream

# unix input stream (keylogger)
keys=JSON.parse(File.read('./keys.json'));
listener=InputListener.new;

ri=0;
bytearr=[];

ARGF.each_byte{|byte|
	ri=(ri+1)%72;

	bytearr.push(byte);

	if (ri==0)
		# Full byte array received
		#puts(bytearr.map{|x| x.to_s(16)}.join(' '));
		eventType=bytearr[44];
		key=bytearr[42];
		if (eventType==1)
			# We're really only interested in keydown events, aren't we?
			#puts("Key: #{keys[key-1]}");
			if keys[key-1]
				listener.down(keys[key-1]);
				listener.status;
			end
		elsif (eventType==2)
			#puts("Hld: #{keys[key-1]}");
			#listener.say(keys[key-1]);
			if keys[key-1]
				listener.hold(keys[key-1]);
				listener.status;
			end
		elsif (eventType==0)
			if keys[key-1]
				listener.up(keys[key-1]);
				listener.status;
			end
		end
		bytearr.clear;
	end
}
