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

function osfreelands_manage_terminal($values) {
	// check if the terminal exists
	$terminals = osfreelands_get_terminals_by_key(array('terminal_key' => $values->objectkey));

	if (is_null($terminals)) {
		drupal_set_message(t('no terminals found by id'));
		// check if there is already a terminal on this region
		$terminals = osfreelands_get_terminals_by_region(array('owner_key' => $values->ownerkey, 'region_name' => $values->region_name));
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
			$values->nid = $terminals[0];
			$terminal = osfreelands_save_terminal($values, FALSE);
			drupal_set_message(t('terminal updated'));
		}
	}
	if (is_null($terminals)) {
		// create a new terminal
		$terminal = osfreelands_save_terminal($values);
		drupal_set_message(t('terminal created'));
	}
	return $terminal;
}

function osfreelands_get_terminals_by_key($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_terminal')
			->fieldCondition('field_osfl_terminal_key', 'value', $values['terminal_key'])
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

function osfreelands_get_terminals_by_region($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_terminal')
			->fieldCondition('field_osfl_terminal_owner_key', 'value', $values['owner_key'])
			->fieldCondition('field_osfl_region_name', 'value', $values['region_name'])
			->execute();
	if (isset($entities['node'])) {
		$nodes_ids = array();
		foreach ($entities['node'] as $n) {
			$nodes_ids[] = $n->nid;
		}
		return $nodes_ids;
	}
	return NULL;
}

function osfreelands_save_terminal($values, $args = array(), $is_new = TRUE) {
	if ($is_new) {
		$node = new stdClass();
		$node->type = 'freelands_terminal';
		node_object_prepare($node);
	}
	else {
		$node = node_load($values->nid);
	}

	$node->uid = 1;

	if (module_exists('d4os_ui_users')) {
		// get the uid of the terminal owner
		$uid = db_query("SELECT uid FROM {d4os_ui_users} WHERE UUID = :uuid", array(':uuid' => $values->ownerkey))->fetchField();
		if ($uid !== FALSE && !is_null($uid)) {
			$node->uid = $uid;
		}
	}
	$node->title = $values->objectname;
	$node->language = LANGUAGE_NONE;

	$node->body[$node->language][0]['value'] = '';
	$node->body[$node->language][0]['summary'] = text_summary('');
	$node->body[$node->language][0]['format'] = 'plain_text';

	$node->field_osfl_terminal_key[$node->language][0]['value'] = $values->objectkey;
	if (isset($args['terminal_url'])) {
		$node->field_osfl_terminal_url[$node->language][0]['value'] = base64_decode($args['terminal_url']);
	}
	$node->field_osfl_terminal_owner_key[$node->language][0]['value'] = $values->ownerkey;
	$node->field_osfl_region_name[$node->language][0]['value'] = $values->region_name;

	node_save($node);
	return $node;
}

function osfreelands_update_terminal($nid, $url) {
	$url = base64_decode($url);

	// check if terminal is answering
	$response = osfreelands_http_request($url . 'ping');
	if ($response->success && $response->code == 200) {
		drupal_set_message(t('The terminal is answering.'));
	}
	else {
		drupal_set_message(t('The terminal is not answering : !error', array('!error' => $response->data . ' (' . $response->code . ')')), 'error');
		drupal_goto('node/' . $nid);
	}

	// get parcels list
	$parcels_list = array();
	$response = osfreelands_http_request($url . 'get-parcels-list');
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
			$operations[] = array('osfreelands_get_parcel_infos', array($parcel, $url, $nid));
		}
		$batch = array(
			'operations' => $operations,
			'file' => drupal_get_path('module', 'osfreelands'). '/osfreelands_parcels.inc',
			'finished' => 'osfreelands_get_parcel_infos_finished',
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

/**********************
 *			INWORLD
 **********************/
function osfreelands_inworld_save_terminal (&$sl, $args) {
	// check if the terminal url is answering
	if (isset($args['terminal_url'])) {
		$response = osfreelands_http_request(base64_decode($args['terminal_url']). 'ping');
		if ($response->code != 200 || $response->data != 'pong') {
			drupal_set_message(t('Terminal is not answering : !error ', array('!error' => $response->message)));
			$sl->response['status'] = FALSE;
			$sl->response['message'] = "error;". osfreelands_get_messages();
			return;
		}
	}
	else {
		drupal_set_message(t('No url given.'));
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". osfreelands_get_messages();
		return;
	}
	// check if the terminal exists
	$terminals = osfreelands_get_terminals_by_key(array('terminal_key' => $sl->objectkey));

	if (is_null($terminals)) {
		drupal_set_message(t('no terminals found by id'));
		// check if there is already a terminal on this region
		$terminals = osfreelands_get_terminals_by_region(array('owner_key' => $sl->ownerkey, 'region_name' => $sl->region_name));
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
			$terminal = osfreelands_save_terminal($sl, $args, FALSE);
			drupal_set_message(t('terminal updated'));
		}
	}
	if (is_null($terminals)) {
		// create a new terminal
		$terminal = osfreelands_save_terminal($sl, $args);
		drupal_set_message(t('terminal created'));
	}
	if (is_object($terminal)) {
		$sl->response['status'] = TRUE;
		$sl->response['message'] = "success;". osfreelands_get_messages();
	}
	else {
		$sl->response['status'] = FALSE;
		$sl->response['message'] = "error;". osfreelands_get_messages();
	}
}
