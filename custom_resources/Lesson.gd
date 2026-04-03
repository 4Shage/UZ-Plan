class_name Lesson
extends Resource

var dtstamp:String
var dtstart:String
var dtend:String
var date:String

var teacher:String
var subgroup:String
var summary:String
var categories:String
var location:String
var description:String

var start_time:String
var end_time:String
var uid:String


func _init(data:Dictionary) -> void:
	dtstamp = data.get("DTSTAMP","")
	dtstart = data.get("DTSTART","")
	dtend = data.get("DTEND","")
	date = data.get("date","")
	teacher = data.get("teacher","")
	subgroup = data.get("subgroup","")
	summary = data.get("SUMMARY","")
	categories = data.get("CATEGORIES","")
	location = data.get("LOCATION","")
	description = data.get("DESCRIPTION","")
	start_time = data.get("start","")
	end_time = data.get("end","")
	uid = data.get("UID","")


func serialize() -> Dictionary:
	return {uid:{
		"DTSTAMP":dtstamp,
		"DTSTART":dtstart,
		"DTEND":dtend,
		"date":date,
		"teacher":teacher,
		"subgroup":subgroup,
		"SUMMARY":summary,
		"CATEGORIES":categories,
		"LOCATION":location,
		"DESCRIPTION":description,
		"start":start_time,
		"end":end_time,
		"UID":uid,
	}}
