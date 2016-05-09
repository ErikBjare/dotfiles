function proc
	ps -ef | grep -v grep | grep $argv
end
