@echo off
setup:
	@echo Setting up Flutter app...
	cd app/flutter && flutter pub get

test:
	cd app/flutter && flutter test
