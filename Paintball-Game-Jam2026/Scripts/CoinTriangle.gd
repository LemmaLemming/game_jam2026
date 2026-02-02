extends BaseCoin
signal triangle_collected

func emit_collection_signal():
	triangle_collected.emit()
