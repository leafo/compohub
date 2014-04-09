<?php

mb_internal_encoding('UTF-8');
mb_http_output('UTF-8');
mb_http_input('UTF-8');

date_default_timezone_set("UTC");

$mysqli = new mysqli("localhost", "root", "", "compohub");
$mysqli->set_charset("utf8");

function slugify($text) { 
  $text = preg_replace('~[^\\pL\d]+~u', '-', $text);
  $text = trim($text, '-');
  $text = strtolower($text);
  $text = preg_replace('~[^-\w]+~', '', $text);
  return $text;
}

function categories_by_id($out=array()) {
	global $mysqli;
	$res = $mysqli->query("select * from gdc2_categories");
	
	if (!$res) {
		echo $mysqli->error;
		return $out;
	}

	while ($row = $res->fetch_assoc()) {
		$out[$row["id"]] = $row;
	}

	foreach ($out as $k => &$v) {
		if ($v["parent"]) {
			$v["parent_obj"] = $out[$v["parent"]];
		}
	}

	return $out;
}

function find_first_value($item, $field) {
	if (!empty($item[$field])) {
		return $item[$field];
	} elseif (!empty($item["parent_obj"])) {
		return find_first_value($item["parent_obj"], $field);
	}
}

function parse_themes($str) {
	if (empty($str)) return;
	$themes = explode(",", $str);
	$themes = array_map(function($theme) {
		return slugify(trim($theme));
	}, $themes);

	return $themes;
}

$parents = categories_by_id();

$res = $mysqli->query("SELECT * FROM gdc2_events where deleted = 0 order by id asc");
$events = array();
while ($row	= $res->fetch_assoc()) {
	$tags = array();
	$parent = isset($parents[$row["parent"]]) ? $parents[$row["parent"]] : false; 
	$row["parent_obj"] = $parent;

	$current_parent = $parent;
	while ($current_parent) {
		$tags[] = slugify($current_parent["name"]);
		$current_parent = isset($current_parent["parent_obj"]) ? $current_parent["parent_obj"] : false;
	}

	$time_format = "Y-m-d h:i:s O";

	if (!empty($row["theme"])) {
		$themes = parse_themes($row["theme"]);
	}

	$event = array(
		"name" => find_first_value($row, "name"),
		"start_date" => date($time_format, $row["start"]),
		"end_date" => date($time_format, $row["end"]),
		"description" => find_first_value($row, "description"),
		"tags" => $tags,
		"themes" => $themes,
		"url" => find_first_value($row, "url")
	);

	if (empty($event["url"])) {
		exit("no url " . print_r($row, true));
	}

	$events[] = $event;
}

echo json_encode(array("jams" => $events), JSON_PRETTY_PRINT);
