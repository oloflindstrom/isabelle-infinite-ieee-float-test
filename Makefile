.PHONY: test fail error run_test watch clean kill tmux-config

test:
	./msg.sh normal $(n)
	@$(MAKE) --no-print-directory run_test m=normal n=$(n) p=$(p)

fail:
	./msg.sh fcheck $(n)
	@$(MAKE) --no-print-directory run_test m=fcheck n=$(n) p=$(p)

error:
	./msg.sh echeck $(n)
	@$(MAKE) --no-print-directory run_test m=echeck n=$(n) p=$(p)

run_test:
	./mktests_testfloat_mod.sh $(m) $(n) $(p)

watch:
	@if ! tmux has-session -t tf-session 2>/dev/null; then \
		tmux new-session -d -s tf-session; \
	fi
	tmux kill-session -t tf-session
	tmux new-session -d -s tf-session

	tmux send-keys 'watch -t -n 0.1 sed -n '1,58p' OUTPUT_stats.log' C-m

	tmux split-window -h -l 60
	tmux send-keys 'watch -t -n 0.1 sed -n '59,117p' OUTPUT_stats.log' C-m

	tmux split-window -h -l 40
	tmux send-keys 'less +F OUTPUT_failed.log' C-m
	
	tmux split-window -h
	tmux send-keys 'less +F OUTPUT_errors.log' C-m
	
	tmux split-window -v -l 1
	tmux send-keys 'watch -t -n 0.1 "wc -l OUTPUT_failed.log OUTPUT_errors.log; \
	echo; [ -s testfloat_gen_error.log ] && echo "--- Warning: TestFloat_gen errors detected" || \
	echo "--- No TestFloat_gen errors detected"; echo; cat msg.txt"' C-m

	gnome-terminal --window --maximize -- tmux attach-session -t tf-session   

clean:
	rm -f lockfile_A lockfile_B lockfile_C lockfile_D

kill:
	-@./testfloat_kill.sh 2>/dev/null
	@$(MAKE) --no-print-directory clean

tmux-config:
	echo "set -g status off" >> ~/.tmux.conf
	tmux source-file ~/.tmux.conf