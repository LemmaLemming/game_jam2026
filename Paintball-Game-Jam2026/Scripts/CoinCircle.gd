extends BaseCoin
signal circle_collected

func emit_collection_signal():
	circle_collected.emit()
