bloom:
	@export PATH="/opt/homebrew/bin:$$PATH"; \
	echo "🌸 Checking for xcodes..."; \
	which xcodes > /dev/null 2>&1 || { \
		echo "xcodes not found, installing..."; \
		brew install xcodesorg/made/xcodes; \
	}; \
	echo "🌸 Selecting Xcode version..."; \
	xcodes install --select; \
	echo "🌸 Opening Xcode..."; \
	open Bloom.xcworkspace
