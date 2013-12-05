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

function osfreelands_get_parcels_by_terminal_nid($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_term_nid', 'target_id', $values['terminal_nid'])
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

function osfreelands_get_parcels_by_owner_key($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_parcel_owner', 'value', $values['owner_key'])
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
	$node->field_osfl_term_nid[$node->language][0]['target_id'] = isset($values->terminal_nid) ? $values->terminal_nid : $node->field_osfl_term_nid[$node->language][0]['target_id'];
	$node->field_osfl_parcel_owner[$node->language][0]['value'] = isset($values->owner) ? $values->owner : $node->field_osfl_parcel_owner[$node->language][0]['value'];
	$node->field_osfl_parcel_location[$node->language][0]['value'] = isset($values->parcel_location) ? $values->parcel_location : $node->field_osfl_parcel_location[$node->language][0]['value'];
	$node->field_osfl_parcel_size[$node->language][0]['value'] = isset($values->area) ? $values->area : $node->field_osfl_parcel_size[$node->language][0]['value'];

	// defines the status
	if (isset($values->parcel_status)) {
		$node->field_osfl_parcel_status[$node->language][0]['value'] = $values->parcel_status;
	}
	else if (isset($node->field_osfl_parcel_status[$node->language][0]['value'])) {
		$node->field_osfl_parcel_status[$node->language][0]['value'] = $node->field_osfl_parcel_status[$node->language][0]['value'];
	}
	else {
		$node->field_osfl_parcel_status[$node->language][0]['value'] = 0;
	}

	// defines the end time
	if (isset($values->end_time)) {
		$node->field_osfl_end_time[$node->language][0]['value'] = $values->end_time;
	}
	else if ($node->field_osfl_end_time[$node->language][0]['value']) {
		$node->field_osfl_end_time[$node->language][0]['value'] = $node->field_osfl_end_time[$node->language][0]['value'];
	}
	else {
		$node->field_osfl_end_time[$node->language][0]['value'] = NULL;
	}

	node_save($node);
	return $node;
}

function osfreelands_add_rent_parcel_button(&$node) {
	// define some vars
	$can_rent = FALSE;
	$status = 'error';
	$message = t('This parcel is not available for renting.');
	$renting_status = $node->field_osfl_parcel_status[$node->language][0]['value'];

	// check if the user is linked on the grid
	$uid = $GLOBALS['user']->uid;
	$user_valid = FALSE;
	if (module_exists('d4os_ui_users')) {
		$uuid = db_query("SELECT uuid FROM {d4os_ui_users} WHERE uid = :uid", array(':uid' => $uid))->fetchField();
		if ($uuid !== FALSE) {
			$user_valid = TRUE;
		}
	}
	else if (module_exists('metaverse_user')) {
		$uuid = metaverse_user_get_uuid($GLOBALS['user']->uid);
		if (!is_null($uuid) && $uuid != UUID_ZERO) {
			$user_valid = TRUE;
		}
	}

	if (!$user_valid) {
		$status = 'error';
		$message = t('You can not rent this parcel because your user is not linked with the grid.');
	}
	else {
		// check if the parcel is available
		if ($renting_status == 0) {
			// check if the user already owns another parcel
			$user_parcels = osfreelands_get_parcels_by_owner_key(array('owner_key' => $uuid));
			$user_parcels_qty = count($user_parcels);
			if (!is_null($user_parcels)) {
				// check if the user can rent another parcel
				$max_allowed = variable_get('osfreelands_max_parcels_per_user', 0);
				if ($max_allowed > 0) {
					if (count($user_parcels) >= $max_allowed ) {
						$status = 'error';
						$message = format_plural($user_parcels_qty,
								'You can not rent this parcel because you already own 1 other parcel.',
								'You can not rent this parcel because you already own @count other parcels.');
					}
				}
				else {
					$can_rent = TRUE;
					$status = 'status';
					$message = t('This parcel is available for renting.');
				}
			}
			else {
				$can_rent = TRUE;
				$status = 'status';
				$message = t('This parcel is available for renting.');
			}
		}
		else {
			// check if the user already owns this parcel
			$owner_key = $node->field_osfl_parcel_owner[$node->language][0]['value'];
			if ($owner_key == $uid) {
				$status = 'status';
				$message = t('You can renew your rent.');
			}
		}
	}

	// display the result
	if (isset($status)) {
		$node->content['osfreelands_status'] = array(
			'#markup' => '<div class="messages ' . $status . '">' . $message . '</div>'
		);
	}
	if ($can_rent) {
		$node->content['osfreelands_rent_button'] = array(
			'#markup' => '<div class="messages ' . $status . '">' . $message . '</div>'
		);
	}
}
/**********************
 *			BATCH
 **********************/
function osfreelands_batch_get_parcel_infos($settings, &$context) {
	$parcel_location = $settings['parcel_location'];
	$terminal_url = $settings['terminal_url'];
	$terminal_nid = $settings['terminal_nid'];
	$default_owner = $settings['default_owner'];
	// init some vars
	$result = "not ok";
	$url = $terminal_url . 'get-parcel-infos?'.urlencode($parcel_location);
	// get the infos inworld
	$response = metaverse_framework_http_request($url);
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
			$parcel_infos->owner = $default_owner;
			$saved_parcel = osfreelands_save_parcel($parcel_infos);
			$result = t('Parcel at !position created.', array('!position' => $parcel_location));
		}
		else {
			// update parcel
			$parcel_infos->nid = $parcels_nids[0];
			$saved_parcel = osfreelands_save_parcel($parcel_infos, FALSE);
			$result = t('Parcel at !position updated.', array('!position' => $parcel_location));
		}
	}
	drupal_set_message($result);
	$context['results'][] = $result;
	$context['message'] = t('Getting infos from !parcel', array('!parcel' => $parcel_location));
}

function osfreelands_batch_get_parcel_infos_finished($success, $results, $operations) {
	if ($success) {
		drupal_set_message(t('Terminal updated.'));
	}
	else {
		$error_operation = reset($operations);
		drupal_set_message(t('An error occurred while processing @operation with arguments : @args', array('@operation' => $error_operation[0], '@args' => print_r($error_operation[0], TRUE))));
	}
	return 'ok';
}
