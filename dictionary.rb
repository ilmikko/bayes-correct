#
# dictionary.rb
#
# This module keeps track of our corpus, i.e. all the 'confirmed' words the user types.
# The confirmations are handled by our context sentence; for example, typing a lot of words in succession and not removing any of them
# will make the words 'in the middle' corrected.
#
# Of course this approach is not perfect: this is why we store the frequency of the gathered words in our corpus. Words with a frequency of 1 aren't probably worth making a note of.
#

require_relative('./data.rb');

# initialize corpus
$data['corpus']={} if $data['corpus'].nil?;

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
		@corpus=$data['corpus'];
	end
end
