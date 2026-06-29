.PHONY: train eval serve test lint

train: # train the model
	uv run train

eval: # evaluate model accuracy
	uv run evaluate

serve: # start the inference API
	uv run serve

test: # run the test suite
	uv run pytest

lint: # check code style
	uv run ruff check .

format: # auto-format code
	uv run ruff format .

notebook: # launch jupyter
	uv run jupyter lab
