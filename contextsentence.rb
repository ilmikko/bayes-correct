#
# contextsentence.rb
#
# This module tries to keep track of what the user is currently typing, here called the "context sentence".
# We don't always know the text the user is editing. But people also make typing mistakes immediately on typing,
# and those features _can_ be tracked. The context sentence is simply an array of words and a cursor position
# in that array. Using this array we can determine whether the user has edited one of the words we are keeping track of.
#

require_relative('./errortracker.rb');
require_relative('./dictionary.rb');

class ContextSentence
	@@dictionary=Dictionary.new;
	@@errortracker=ErrorTracker.new;
	def currentword; @sentence[@cursor[0]]; end
	def previousword; @sentence[@cursor[0]-1]; end
	def nextword; @sentence[@cursor[0]+1]; end
	def status
		word = currentword[0..-1] << " ";
		if word.length>1
			# display cursor in word
			word.insert(@cursor[1]+1,"\e[m");
			word.insert(@cursor[1],"\e[7m");
		end

		"#{@@errortracker.status}\r\n#{@@dictionary.status}\r\nCursor: #{@cursor}\r\nContext Word: #{word}\r\nContext Sentence: #{@sentence}"
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
