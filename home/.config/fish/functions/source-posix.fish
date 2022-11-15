# Sources a sh/bash-compatible .env file into fish
function source-posix
	for i in (cat $argv)
        # if line is a comment or empty, skip it
        if test (echo $i | cut -c1) = "#" -o -z $i
            continue
        end
		set arr (echo $i |tr = \n)
  		set -gx $arr[1] $arr[2]
	end
end

