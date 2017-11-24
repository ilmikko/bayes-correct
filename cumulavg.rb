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
