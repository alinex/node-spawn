Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.0.2 (2015-03-19)
-------------------------------------------------
- Optimized debug of command line with environment and encoding.
- Fixed nice values.
- Adding hint for multiple runs to error message.

Version 1.0.1 (2015-03-19)
-------------------------------------------------
- Allow to change configsearch path.

Version 1.0.0 (2015-03-19)
-------------------------------------------------
- Make tests faster by checking only two retries.
- Document retry timeout handling.
- Added default check for no stderr output.
- Fixed retry handling to correct count.
- Allow errors to be returned and handled without try.
- Try to handle process close on signals.
- Added logging, tests and use nice settings within valid range.
- Enable debug output to be line oriented.
- Added lines-adapter to better stream output line oriented.
- Restructure to use newer config access and support balance-config.
- Update documentation syntax.
- Small fixes.
- Upgraded dependent packages.
- Fixed gid setting and added input specification.
- Try to fix unknown error thwown bug.

Version 0.1.6 (2015-02-03)
-------------------------------------------------
- Added local configs to search path if used as module, also.
- Fixed Spawn initialization to prevent parallel runs.
- Make configcheck public available.
- Spellchecked inline comment.

Version 0.1.5 (2015-01-07)
-------------------------------------------------
- Fixed search path for own configs.

Version 0.1.4 (2014-12-23)
-------------------------------------------------
- Added search for configs in this package.
- Documented the configuration changes.
- Fixed configuration loading.
- Extracted configuration into file.
- Added configuration file.
- Allow newer sub packages.

Version 0.1.1 (2014-12-09)
-------------------------------------------------
- Bug fixes.

Version 0.1.0 (2014-12-08)
-------------------------------------------------
- Bug with array clone.

Version 0.0.2 (2014-12-08)
-------------------------------------------------
- Added support for windows.
- Add wait and retry events.
- Optimized debugging and retry.
- Added retry handling after failure.
- Fixed line length in code.
- Made weight calculation cpu dependent.
- Added nice settings for priorities on os.
- Fine Tuning and documentation.
- Small fixes in debug output.
- Fixed typo bug.
- Moved machine setup into class to make it customizable.
- Finalized process load balancing.
- Added load handling with weight measurement.
- Added changes of success checking in documentation.
- Remove success method and run it automatically.

Version 0.0.1 (2014-11-18)
-------------------------------------------------
- Added success check.
- Principal spawn call running.
- Made package ready to run tests.
- Added initial test routine.
- Initial files configured and basic Class structure designed.
- Initial commit

