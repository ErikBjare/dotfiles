#/usr/bin/fish

# Tries to source a bash env file line by line with fish,
# skips lines that start with '#'
function source-posix
	for i in (cat $argv)
        # echo "line: $i"
        switch $i
            case '#*'
                #echo "comment $i skipped"
            case ''
                #echo "empty line skipped"
            case '*'
                echo "set $i"
                set arr (echo $i |tr = \n)
                set -gx $arr[1] $arr[2]
        end
	end
end
