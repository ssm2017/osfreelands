<?php

/**
 * @package    osFreeLands
 * @copyright Copyright (C) 2013 Wene - ssm2017 Binder ( S.Massiaux ). All rights reserved.
 * @license   GNU/GPL, http://www.gnu.org/licenses/gpl-2.0.html
 * osFreeLands is free software. This version may have been modified pursuant
 * to the GNU General Public License, and as distributed it includes or
 * is derivative of works licensed under the GNU General Public License or
 * other free or open source software licenses.
 */

function osfreelands_manage_parcels($terminal, $args) {
	// get the parcels
	if (isset($args['parcels']) && !empty($args['parcels'])) {
		$parcels = drupal_json_decode(base64_decode($args['parcels']));
		if (!is_array($parcels)) {
			drupal_set_message(t('Error decoding parcels list.'), 'error');
			return NULL;
		}
		metaverse_framework_debug("-----------------------------");
		metaverse_framework_debug("parcels : " . print_r($parcels, true));
		metaverse_framework_debug("-----------------------------");
	}
	else {
		drupal_set_message(t('No parcels submitted.'), 'error');
		return NULL;
	}
	$saved_parcels = array();
	foreach ($parcels as $parcel) {
		// check if uuid
		if (!osfreelands_check_uuid($parcel[0])) {
			drupal_set_message(t('Error with parcel uuid.'), 'error');
			return NULL;
		}
		// fill values
		$duration = variable_get('osfreelands_renting_duration', 0);
		// uuid; location; size; name; description
		$values = new stdclass();
		$values->parcel_key = $parcel[0];
		$values->parcel_location = isset($parcel[1]) ? $parcel[1] : "<128;128;128>";
		$values->parcel_size = isset($parcel[2]) ? $parcel[2] : "0";
		$values->parcel_name = isset($parcel[3]) ? $parcel[3] : "No name";
		$values->parcel_description = isset($parcel[4]) ? $parcel[4] : "No desc";
		$values->terminal_nid = $terminal->nid;
		$values->parcel_status = 0;
		$values->parcel_owner_key = $terminal->field_osfl_terminal_owner_key[LANGUAGE_NONE][0]['value'];
		// get parcel by uuid
		$parcels_nids = osfreelands_get_parcels_by_parcel_key(array('parcel_key' => $parcel[0]));
		if (is_null($parcels_nids)) {
			// create a new parcel
			$values->end_time = ($duration > 0) ? date() + (86400 * $duration) : NULL;
			$saved_parcel = osfreelands_save_parcel($values);
			drupal_set_message(t('Parcel created'));
		}
		else {
			// update parcel
			$values->nid = $parcels_nids[0];
			$saved_parcel = osfreelands_save_parcel($values, FALSE);
			drupal_set_message(t('Parcel updated'));
		}
		$saved_parcels[] = $saved_parcel->nid;
	}
	// check if the terminal contains parcels
	$terminal_parcels = osfreelands_get_parcels_by_terminal_nid(array('terminal_nid' => $terminal->nid));
	if (count($terminal_parcels)) {
		foreach ($terminal_parcels as $terminal_parcel) {
			// check if parcel was saved (to delete old parcels)
			if (!in_array($terminal_parcel, $saved_parcels)) {
				node_delete($terminal_parcel);
				drupal_set_message(t('Parcel deleted.'));
			}
		}
	}
	return $saved_parcels;
}

function osfreelands_get_parcels_by_terminal_nid($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_terminal_nid', 'target_id', $values['terminal_nid'])
			->execute();
	if (isset($entities['node'])) {
		$nodes_ids = array();
		foreach ($entities['node'] as $n) {
			$nodes_ids[] = $n->nid;
		}
		// get the nodes
		return $nodes_ids;
	}
	return NULL;
}

function osfreelands_get_parcels_by_parcel_key($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_parcel_key', 'value', $values['parcel_key'])
			->execute();
	if (isset($entities['node'])) {
		$nodes_ids = array();
		foreach ($entities['node'] as $n) {
			$nodes_ids[] = $n->nid;
		}
		// get the nodes
		return $nodes_ids;
	}
	return NULL;
}

function osfreelands_get_parcels_by_parcel_nid($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->propertyCondition('nid', $values['nid'])
			->execute();
	if (isset($entities['node'])) {
		$nodes_ids = array();
		foreach ($entities['node'] as $n) {
			$nodes_ids[] = $n->nid;
		}
		// get the nodes
		return $nodes_ids;
	}
	return NULL;
}

function osfreelands_save_parcel($values, $is_new = TRUE) {
	/*
	 * name
	 * desc
	 * owner
	 * area
	 * uuid
	 */
	if ($is_new) {
		$node = new stdClass();
		$node->type = 'freelands_parcel';
		node_object_prepare($node);
	}
	else {
		$node = node_load($values->nid);
	}

	$node->title = isset($values->name) ? $values->name : $node->title;
	$node->language = LANGUAGE_NONE;

	$node->body[$node->language][0]['value'] = isset($values->desc) ? $values->desc : $node->body[$node->language][0]['value'];
	$node->body[$node->language][0]['summary'] = text_summary(isset($values->desc) ? $values->desc : $node->body[$node->language][0]['summary']);
	$node->body[$node->language][0]['format'] = 'plain_text';

	$node->field_osfl_parcel_key[$node->language][0]['value'] = isset($values->uuid) ? $values->uuid : $node->field_osfl_parcel_key[$node->language][0]['value'];
	$node->field_osfl_terminal_nid[$node->language][0]['target_id'] = isset($values->terminal_nid) ? $values->terminal_nid : $node->field_osfl_terminal_nid[$node->language][0]['target_id'];
	$node->field_osfl_parcel_status[$node->language][0]['value'] = isset($values->parcel_status) ? $values->parcel_status : $node->field_osfl_parcel_status[$node->language][0]['value'];
	$node->field_osfl_parcel_owner_key[$node->language][0]['value'] = isset($values->owner) ? $values->owner : $node->field_osfl_parcel_owner_key[$node->language][0]['value'];
	$node->field_osfl_parcel_location[$node->language][0]['value'] = isset($values->parcel_location) ? $values->parcel_location : $node->field_osfl_parcel_location[$node->language][0]['value'];
	$node->field_osfl_parcel_size[$node->language][0]['value'] = isset($values->area) ? $values->area : $node->field_osfl_parcel_size[$node->language][0]['value'];
	$node->field_osfl_end_time[$node->language][0]['value'] = isset($values->end_time) ? $values->end_time : isset($node->field_osfl_end_time[$node->language][0]['value']) ? $node->field_osfl_end_time[$node->language][0]['value'] : NULL;

	node_save($node);
	return $node;
}

/**********************
 *			BATCH
 **********************/
function osfreelands_get_parcel_infos($parcel_location, $terminal_url, $terminal_nid, &$context) {
	// init some vars
	$result = "not ok";
	$url = $terminal_url . 'get-parcel-infos?'.urlencode($parcel_location);
	// get the infos inworld
	$response = osfreelands_http_request($url);
	if ($response->success && $response->code == 200) {
		// parse infos received
		$parcel_infos = (object)drupal_json_decode(base64_decode($response->data));
		$parcel_infos->terminal_nid = $terminal_nid;
		$parcel_infos->parcel_location = $parcel_location;
		// get parcel by uuid
		$duration = variable_get('osfreelands_renting_duration', 0);
		$parcels_nids = osfreelands_get_parcels_by_parcel_key(array('parcel_key' => $parcel_infos->uuid));
		if (is_null($parcels_nids)) {
			// create a new parcel
			$parcel_infos->end_time = ($duration > 0) ? date() + (86400 * $duration) : NULL;
			$saved_parcel = osfreelands_save_parcel($parcel_infos);
			$result = t('Parcel at !position created.', array('!position' => $parcel_location));
		}
		else {
			// update parcel
			$saved_parcel->nid = $parcels_nids[0];
			$saved_parcel = osfreelands_save_parcel($saved_parcel, FALSE);
			$result = t('Parcel at !position updated.', array('!position' => $parcel_location));
		}
	}
	$context['results'][] = $result;
	$context['message'] = t('Getting infos from !parcel', array('!parcel' => $parcel_location));
}

function osfreelands_get_parcel_infos_finished($success, $results, $operations) {
	if ($success) {
		drupal_set_message(t('Terminal updated.'));
	}
	else {
		$error_operation = reset($operations);
		drupal_set_message(t('An error occurred while processing @operation with arguments : @args', array('@operation' => $error_operation[0], '@args' => print_r($error_operation[0], TRUE))));
	}
	return 'ok';
}
