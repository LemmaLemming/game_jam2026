extends BaseCoin
signal square_collected

func emit_collection_signal():
	square_collected.emit()
