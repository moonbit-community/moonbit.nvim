DEPS_DIR := .deps
PLENARY_DIR := $(DEPS_DIR)/plenary.nvim

.PHONY: test deps clean

deps: $(PLENARY_DIR)

$(PLENARY_DIR):
	@mkdir -p $(DEPS_DIR)
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR)

test: deps
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

clean:
	rm -rf $(DEPS_DIR)
