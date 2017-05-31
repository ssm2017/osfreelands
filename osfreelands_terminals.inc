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

function osfreelands_get_terminals_by_key($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_terminal')
			->fieldCondition('field_osfl_term_key', 'uuid_field', $values['terminal_key'])
			->execute();
	if (isset($entities['node'])) {
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_get_terminals_by_region($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_terminal')
			->fieldCondition('field_osfl_term_owner', 'target_id', $values['owner_uid'])
			->fieldCondition('field_osfl_region_name', 'value', $values['region_name'])
			->execute();
	if (isset($entities['node'])) {
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_get_terminals_by_owner_uid($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_terminal')
			->fieldCondition('field_osfl_term_owner', 'target_id', $values['owner_uid'])
			->execute();
	if (isset($entities['node'])) {
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_save_terminal($values, $is_new = TRUE) {
	if ($is_new) {
		$node = new stdClass();
		$node->type = 'freelands_terminal';
		node_object_prepare($node);
		$node->language = LANGUAGE_NONE;
	}
	else {
		$node = node_load($values->nid);
	}

	// fill other values
	$node->uid = $values->owner_uid;
	$node->title = $values->objectname;

	$node->body[$node->language][0]['value'] = '';
	$node->body[$node->language][0]['format'] = 'plain_text';

	// terminal uuid
	$node->field_osfl_term_key[$node->language][0]['uuid_field'] = $values->objectkey;
	// terminal url
	if (isset($values->terminal_url)) {
		$node->field_osfl_term_url[$node->language][0]['value'] = base64_decode($values->terminal_url);
	}
	// owner uid
	$node->field_osfl_term_owner[$node->language][0]['target_id'] = $values->owner_uid;
	// default owner uid
	$node->field_osfl_term_default_owner[$node->language][0]['target_id'] = $values->default_owner_uid;
	// region name
	$node->field_osfl_region_name[$node->language][0]['value'] = $values->region_name;
	// terminal location
	$node->field_osfl_term_location[$node->language][0]['value'] = '<'.floor($values->position_x).','.floor($values->position_y).','.floor($values->position_z).'>';
  // password
  $node->field_osfl_term_pass[$node->language][0]['value'] = $values->terminal_password;
  // max_parcels_per_user
  $node->field_osfl_max_parcels[$node->language][0]['value'] = $values->max_parcels_per_user;
  // renting_duration
  $node->field_osfl_rent_duration[$node->language][0]['value'] = $values->renting_duration;
	// last online
	if (isset($values->last_online)) {
		$node->field_osfl_last_online[$node->language][0]['value'] = $values->last_online;
	}
	node_save($node);

  // assign role to owner
  osfreelands_set_role($values->owner_uid, 'terminal');

	return $node;
}

function osfreelands_update_terminal($nid) {
	// get the terminal
	$terminal = osfreelands_ping_terminal($nid);
	if ($terminal->online_status != 'online') {
		drupal_goto('node/'.$nid);
	}

	$url = $terminal->field_osfl_term_url[$terminal->language][0]['value'];
	// get parcels list
	$parcels_list = array();
	$response = metaverse_framework_http_request($url . '/?q=get-parcels-list');
	if ($response->success && $response->code == 200) {
		drupal_set_message(t('Parcel list received.'));
		$parcels_list = drupal_json_decode(base64_decode($response->data));
	}
	else {
		drupal_set_message(t('Unable to get the parcels list : !error', array('!error' => $response->data . ' (' . $response->code . ')')), 'error');
		drupal_goto('node/' . $nid);
	}

	// get parcels infos
	if (count($parcels_list)) {
		module_load_include('inc', 'osfreelands', 'osfreelands_parcels');
		$operations = array();
		foreach ($parcels_list as $parcel) {
			$settings = array(
				'parcel_location' => $parcel,
				'terminal_url' => $url,
				'terminal_nid' => $nid,
				'default_owner_uid' => $terminal->field_osfl_term_default_owner[$terminal->language][0]['target_id']
			);
			$operations[] = array('osfreelands_batch_get_parcel_infos', array($settings));
		}
		$batch = array(
			'operations' => $operations,
			'file' => drupal_get_path('module', 'osfreelands'). '/osfreelands_parcels.inc',
			'finished' => 'osfreelands_batch_get_parcel_infos_finished',
			'title' => t('Parcel infos'),
			'init_message' => t('Retrieving parcel infos.'),
			'progress_message' => t('Processed @current out of @total.'),
			'error_message' => t('Retrieving parcels infos has encountered an error.'),
		);
		batch_set($batch);
		batch_process('node/' . $nid);
	}
	else {
		drupal_set_message(t('No parcel found.'), 'error');
		drupal_goto('node/' . $nid);
	}
}

function osfreelands_delete_terminals($terminals_nids) {
  module_load_include('inc', 'osfreelands', 'osfreelands_parcels');
	foreach ($terminals_nids as $terminal_nid) {
		// delete parcels
		$parcels_nids = osfreelands_get_parcels_by_terminal_nid(array('terminal_nid' => $terminal_nid));
		if (!is_null($parcels_nids)) {
			node_delete_multiple($parcels_nids);
		}
	}
	// delete terminals
	node_delete_multiple($terminals_nids);
}

function osfreelands_display_update_terminal_button(&$node) {
	// ping terminal
	$terminal = osfreelands_ping_terminal($node->nid);
	// upate link
	if ($terminal->online_status == 'online' && ($GLOBALS['user']->uid == $node->uid || user_access('osfl manage terminals'))) {
		$node->content['osfreelands_updater'] = array(
			'#type' => 'link',
			'#title' => t('Update terminal'),
			'#href' => 'freelands/terminals/update/' . $node->nid,
		);
	}
}

/**********************
 *			INWORLD
 **********************/
function osfreelands_inworld_save_terminal (&$sl, $args) {
	// check if the terminal url is answering
	if (isset($args['terminal_url'])) {
		$response = metaverse_framework_http_request(base64_decode($args['terminal_url']). '/?q=ping');
		if ($response->code != 200 || $response->data != 'pong') {
			drupal_set_message(t('Terminal is not answering : !error ', array('!error' => $response->message)));
			$sl->response['status'] = FALSE;
			$sl->response['message'] = "error;". metaverse_framework_get_messages();
			return;
		}
	}
	else {
		drupal_set_message(t('No url given.'));
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". metaverse_framework_get_messages();
		return;
	}

	// check if the owner is registered on the website
	$sl->owner_uid = osfreelands_get_uid_by_uuid($sl->ownerkey);
	if (!$sl->owner_uid) {
		drupal_set_message(t('Owner not registered on the website.'));
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". metaverse_framework_get_messages();
		return;
	}

	// check if the default owner is registered on the website
	$sl->default_owner_uid = osfreelands_get_uid_by_uuid($args['default_owner']);
	if (!$sl->default_owner_uid) {
		drupal_set_message(t('Default owner not registered on the website.'));
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". metaverse_framework_get_messages();
		return;
	}

	// fill some default values
	$sl->terminal_url = $args['terminal_url'];
	$sl->last_online = time();
  $sl->terminal_password = $args['terminal_password'];
  $sl->max_parcels_per_user = $args['max_parcels_per_user'];
  $sl->renting_duration = $args['renting_duration'];

	// check if the terminal exists
	$terminals = osfreelands_get_terminals_by_key(array('terminal_key' => $sl->objectkey));
	if (is_null($terminals)) {
		drupal_set_message(t('no terminals found by id'));
		// check if there is already a terminal on this region
		$terminals = osfreelands_get_terminals_by_region(array('owner_uid' => $sl->owner_uid, 'region_name' => $sl->region_name));
		if (!is_null($terminals)) {
			drupal_set_message(t('!qty terminals found by region', array('!qty' => count($terminals))));
			// delete terminals
			osfreelands_delete_terminals($terminals);
			$terminals = NULL;
			drupal_set_message(t('terminals deleted'));
		}
	}
	else {
		if (count($terminals) > 1) {
			// delete terminals
			osfreelands_delete_terminals($terminals);
			$terminals = NULL;
			drupal_set_message(t('terminals deleted'));
		}
		else {
			// update terminal
			$sl->nid = $terminals[0];
			$terminal = osfreelands_save_terminal($sl, FALSE);
			drupal_set_message(t('terminal updated'));
		}
	}
	if (is_null($terminals)) {
		// create a new terminal
		$terminal = osfreelands_save_terminal($sl);
		drupal_set_message(t('terminal created'));
	}
	if (is_object($terminal)) {
		// send the answer
		$sl->response['status'] = TRUE;
		$sl->response['message'] = "success;". metaverse_framework_get_messages();
	}
	else {
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". metaverse_framework_get_messages();
	}
}

function osfreelands_ping_terminal($terminal_nid) {
	// get the terminal
	$terminal = node_load($terminal_nid);

	// get the url
	$url = $terminal->field_osfl_term_url[$terminal->language][0]['value'];

	// check if terminal is answering
	$response = osfreelands_ping_terminal_by_url($url);
	if ($response->online_status == 'online') {
		$terminal->last_online = time();
		node_save($terminal);
	}
	$terminal->online_status = $response->online_status;
	drupal_set_message($response->message, $response->error_level);
	return $terminal;
}

function osfreelands_ping_terminal_by_url($url) {
	// check if terminal is answering
	$response = metaverse_framework_http_request($url . '/?q=ping');
	if ($response->success && $response->code == 200) {
		if ($response->data == 'pong') {
			$response->error_level = 'status';
			$response->message = t('The terminal is answering.');
			$response->online_status = 'online';
		}
		else if ($response->data == 'idle') {
			$response->error_level = 'warning';
			$response->message = t('Terminal is online but it is stopped (needs a reset)');
			$response->online_status = 'idle';
		}
		else {
			$response->error_level = 'error';
			$response->message = t('Terminal is online but there is an error : !error', array('!error' => $response->data));
			$response->online_status = 'error';
		}
	}
	else {
		$response->error_level = 'error';
		$response->message = t('The terminal is not answering : !error', array('!error' => $response->data . ' (' . $response->code . ')'));
		$response->online_status = 'offline';
	}
	return $response;
}