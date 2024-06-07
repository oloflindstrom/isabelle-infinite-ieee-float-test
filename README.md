# isabelle-infinite-ieee-float-test

## Dependencies

The terminal multiplexer tmux must be installed to use the monitoring tool:

`sudo apt-get install tmux`

## Supported operating systems

So far, only Debian based x86_64 Linux systems have been tested. Using any system that deviates from Linux-x86_64 requires new builds of TestFloat/SoftFloat. See the TestFloat/SoftFloat folders for more information.

## Change permissions for scripts and the executable

`chmod +x mktests_testfloat_mod.sh mktests_testfloat_mod_aux.sh testfloat_kill.sh msg.sh fp_test/fp_test`

*Note that permissions need to be changed not only for the shell scripts, but also for the executable* `fp_test/fp_test`.

## Regarding sudo rights

If a limited number of tests are run, the scripts will stop automatically once the testing is finished. To abort a testing session before it has finished, or when exiting an infinite testing session, sudo rights are needed. All instances of `mktests_testfloat_mod_aux.sh` needs to be terminated, which is achieved by using the command `make kill`. Inspect `testfloat_kill.sh` for viewing the actual command. Please note that if you do not have sudo rights, the infinite testing mode cannot be stopped -- you will have to reboot the system, or sign out from the session in some other way. Therefore, there is a disclaimer before starting the testing, which requires the user to enter "y/Y" in order to continue.

*If the user neither has sudo rights, nor can end the session (as could be the case if ssh is used to access a host), infinite testing should not be conducted, since only an admin could stop the scripts.*

## Commands (using the monitoring tool)

Test all 116 combinations and process *n* test vectors per combination (in the example, *n* = 5):

`make test watch n=5`

Infinite testing of all 116 combinations:

`make test watch n=inf`

Include a debug file (`OUTPUT_debug.log`) consisting of all processed test vectors:

`make test watch n=5 p=debug`

Run `fcheck` mode, which deliberately creates faulty test vectors (i.e., most of the time, a significant amount of test cases will fail). This is useful for guaranteeing that the testing framework is functioning. If, e.g., permissions are not granted for the `fp_test` executable, there will be no failed test cases when running the fail-check mode:

`make fail watch n=5`

Run `echeck` mode, which -- if the testing framework is functioning correctly -- will always output an error message per processed test vector:

`make error watch n=5`

Abort the testing and remove all the lockfiles:

`make kill`

Only clean up the lockfiles:

`make clean`

*Note that all the log files will be overwritten if a new testing session is started.*

## Commands (without using the monitoring tool)

Simply remove the `watch` command. The log files will have to be refreshed and inspected manually.

## Additional information

- There is a separate error log for TestFloat errors, and for errors caught when piping to the executable. This log file must be checked manually to inspect its contents. The only information provided by the monitoring tool is the output "--- No TestFloat_gen errors detected" or "--- Warning: TestFloat_gen errors detected".

- Use `Ctrl+-` and `Ctrl++` to zoom in and out in the tmux monitoring tool when the text is too big to be contained in the panes, or too small to be viewed clearly. 

- `make tmux-config` can be used to get rid of the green line/bar at the bottom of the command line window. Note that this will affect all use cases of tmux for the current user, and not solely when running this testing framework. Fullscreen mode is recommended while using the monitoring tool (`F11` for, e.g., GNOME terminal).

## License and credits

 



 

