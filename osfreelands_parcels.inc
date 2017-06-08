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
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_get_parcels_by_parcel_key($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_parcel_key', 'uuid_field', $values['parcel_key'])
			->execute();
	if (isset($entities['node'])) {
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_get_parcels_by_owner_key($values) {
	$uid = osfreelands_get_uid_by_uuid($values['owner_key']);
	return osfreelands_get_parcels_by_owner_uid(array('owner_uid' => $uid));
}

function osfreelands_get_parcels_by_owner_uid($values) {
	$query = new EntityFieldQuery();
	$entities = $query->entityCondition('entity_type', 'node')
			->propertyCondition('type', 'freelands_parcel')
			->fieldCondition('field_osfl_parcel_owner', 'target_id', $values['owner_uid'])
			->execute();
	if (isset($entities['node'])) {
		return array_keys($entities['node']);
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
		return array_keys($entities['node']);
	}
	return NULL;
}

function osfreelands_save_parcel($values, $is_new = TRUE) {
	/*
	 * parcel_name
	 * parcel_desc
	 * parcel_owner
	 * parcel_area
	 * parcel_uuid
	 */
	if ($is_new) {
		$node = new stdClass();
		$node->type = 'freelands_parcel';
		node_object_prepare($node);
		$node->language = LANGUAGE_NONE;
	}
	else {
		$node = node_load($values->nid);
	}

	$node->title = isset($values->parcel_name) ? $values->parcel_name : $node->title;

	$node->body[$node->language][0]['value'] = isset($values->parcel_desc) ? $values->parcel_desc : $node->body[$node->language][0]['value'];
	$node->body[$node->language][0]['format'] = 'plain_text';

	$node->field_osfl_parcel_key[$node->language][0]['uuid_field'] = isset($values->parcel_uuid) ? $values->parcel_uuid : $node->field_osfl_parcel_key[$node->language][0]['uuid_field'];
	$node->field_osfl_term_nid[$node->language][0]['target_id'] = isset($values->terminal_nid) ? $values->terminal_nid : $node->field_osfl_term_nid[$node->language][0]['target_id'];
	$node->field_osfl_parcel_location[$node->language][0]['value'] = isset($values->parcel_location) ? $values->parcel_location : $node->field_osfl_parcel_location[$node->language][0]['value'];
	$node->field_osfl_parcel_size[$node->language][0]['value'] = isset($values->parcel_area) ? $values->parcel_area : $node->field_osfl_parcel_size[$node->language][0]['value'];

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
	else if (isset($node->field_osfl_end_time[$node->language][0]['value'])) {
		$node->field_osfl_end_time[$node->language][0]['value'] = $node->field_osfl_end_time[$node->language][0]['value'];
	}
	else {
		$node->field_osfl_end_time[$node->language][0]['value'] = NULL;
	}

	// defines the owner
	if (isset($values->parcel_owner_uid)) {
		$node->field_osfl_parcel_owner[$node->language][0]['target_id'] = $values->parcel_owner_uid;
	}

	node_save($node);
	return $node;
}

function osfreelands_display_rent_parcel_button(&$node) {
	// check if rentable by the actual user
	$uid = $GLOBALS['user']->uid;
	$rentable = osfreelands_check_parcel_rentable_by_uid($node, $uid);

	// display the result
	if (isset($rentable->status)) {
		$node->content['osfreelands_status'] = array(
			'#markup' => '<div class="messages ' . $rentable->status . '">' . $rentable->message . '</div>',
			'#weight' => -2
		);
	}
	if ($rentable->can_rent) {
		$node->content['osfreelands_rent_button'] = array(
			'#type' => 'link',
			'#title' => t('Click here to rent this parcel'),
			'#href' => 'freelands/parcels/rent/' . $node->nid . '/' . $uid,
			'#weight' => -1
		);
	}
}

function osfreelands_display_parcel_region_name(&$node) {
	$terminal = node_load($node->field_osfl_term_nid[$node->language][0]['target_id']);
	if (is_object($terminal)) {
		$node->content['osfreelands_region_name'] = field_view_field('node', $terminal, 'field_osfl_region_name', $terminal->field_osfl_region_name[$terminal->language][0]);
	}
}

function osfreelands_check_parcel_rentable_by_uid(&$parcel, $uid) {
	$answer = new stdClass();
	$answer->uid = $uid;
	$answer->uuid = NULL;
	$answer->can_rent = FALSE;
	$answer->status = 'error';
	$answer->message = t('This parcel is not available for renting.');

	// check if the user is linked on the grid
	$uuid = osfreelands_get_uuid_by_uid($uid);

	if (!$uuid) {
		$answer->status = 'error';
		$answer->message = t('You can not rent this parcel because your user is not linked with the grid.');
	}
	else {
		$answer->uuid = $uuid;
		// check if the parcel is available
		if ($parcel->field_osfl_parcel_status[$parcel->language][0]['value'] == 0) {
			// check if the user already owns another parcel
			$user_parcels = osfreelands_get_parcels_by_owner_uid(array('owner_uid' => $uid));
			$user_parcels_qty = count($user_parcels);
			if (!is_null($user_parcels)) {
				// get the terminal
				$terminal = node_load($parcel->field_osfl_term_nid[$parcel->language][0]['target_id']);
				// check if the user can rent another parcel
				$max_allowed = $terminal->field_osfl_max_parcels[$terminal->language][0]['value'];
				if ($max_allowed > 0) {
					if (count($user_parcels) >= $max_allowed) {
						$answer->status = 'error';
						$answer->message = format_plural($user_parcels_qty, 'You can not rent this parcel because you already own 1 other parcel.', 'You can not rent this parcel because you already own @count other parcels.');
					}
				}
				else {
					$answer->can_rent = TRUE;
					$answer->status = 'status';
					$answer->message = t('This parcel is available for renting.');
				}
			}
			else {
				$answer->can_rent = TRUE;
				$answer->status = 'status';
				$answer->message = t('This parcel is available for renting.');
			}
		}
		else {
			// check if the user already owns this parcel
			if ($parcel->field_osfl_parcel_owner[$parcel->language][0]['target_id'] == $uid) {
				$answer->can_rent = TRUE;
				$answer->status = 'status';
				$answer->message = t('You can renew your rent.');
			}
		}
	}
	return $answer;
}

function osfreelands_rent_parcel_callback($nid, $uid) {
	$parcel = node_load($nid);
	$success = FALSE;

	// double check
	$new_owner = osfreelands_check_parcel_rentable_by_uid($parcel, $uid);
	if (!$new_owner->can_rent) {
		drupal_set_message($new_owner->message, $new_owner->status);
		drupal_goto('node/' . $nid);
	}

	// get the terminal
	module_load_include('inc', 'osfreelands', 'osfreelands_terminals');
	$terminal = osfreelands_ping_terminal($parcel->field_osfl_term_nid[$parcel->language][0]['target_id']);
	if ($terminal->online_status != 'online') {
		drupal_set_message(t('Terminal is not answering'));
		drupal_goto('node/'.$nid);
	}

  // set values inworld
  $values = array(
    'terminal_url' => $terminal->field_osfl_term_url[$terminal->language][0]['value'],
    'terminal_password' => $terminal->field_osfl_term_pass[$terminal->language][0]['value'],
    'parcel_location' => $parcel->field_osfl_parcel_location[$parcel->language][0]['value'],
    'owner_uuid' => $new_owner->uuid
  );
  $response = osfreelands_update_parcel_inworld($values);

  if ($response != Null) {
    if ($response->parcel_owner != $new_owner->uuid) {
      drupal_set_message(t('Error saving parcel inworld'));
      drupal_goto('node/'.$nid);
    }
  }
  else {
    drupal_set_message(t('Error saving parcel inworld'));
    drupal_goto('node/'.$nid);
  }

	// save the parcel
	$parcel->parcel_owner_uid = $new_owner->uid;
	$parcel->parcel_status = 2;
	$renting_duration = $terminal->field_osfl_rent_duration[$terminal->language][0]['value'];
	if ($renting_duration) {
		$parcel->end_time = time() + (86400 * $renting_duration);
	}
	osfreelands_save_parcel($parcel, FALSE);

	// assign role to owner
	osfreelands_set_role($parcel->parcel_owner_uid, 'parcel');

  // return to the parcel page
	drupal_goto('node/' . $nid);
}

function osfreelands_update_parcel_inworld($values) {
	// send the info inworld
	$url = $values['terminal_url']
			. '?q=rent-parcel&password=' . $values['terminal_password']. '&parcel='.  urlencode($values['parcel_location']). '&owner='. $values['owner_uuid'];
	$response = metaverse_framework_http_request($url);
	if ($response->success && $response->code == 200) {
		// parse infos received
		$parcel_infos = (object) drupal_json_decode(base64_decode($response->data));
		if ($parcel_infos->parcel_owner == $values['owner_uuid']) {
			// update the parcel
			drupal_set_message(t('Parcel rented.'));
      return $parcel_infos;
		}
		else {
			drupal_set_message(t('There was an error when saving parcel.'), 'error');
		}
	}
	else {
		drupal_set_message(t('Terminal error : !error', array('!error' => $response->code)), 'error');
	}
  return Null;
}

/* * ********************
 * 			BATCH
 * ******************** */

function osfreelands_batch_get_parcel_infos($settings, &$context) {
	// init some vars
	$parcel_location = $settings['parcel_location'];
	$terminal_url = $settings['terminal_url'];
	$terminal_nid = $settings['terminal_nid'];
	$default_owner_uid = $settings['default_owner_uid'];
	$default_owner_uuid = osfreelands_get_uuid_by_uid($default_owner_uid);
	$result = "not ok";
	$url = $terminal_url . '/?q=get-parcel-infos&parcel=' . urlencode($parcel_location);

	// get the infos inworld
	$response = metaverse_framework_http_request($url);
	if ($response->success && $response->code == 200) {

		// parse infos received
		$parcel_infos = (object) drupal_json_decode(base64_decode($response->data));
		$parcel_infos->terminal_nid = $terminal_nid;
		$parcel_infos->parcel_location = $parcel_location;

		// get parcel by uuid
		$parcels_nids = osfreelands_get_parcels_by_parcel_key(array('parcel_key' => $parcel_infos->parcel_uuid));

		// check the owner uid
		$parcel_infos->parcel_owner_uid = osfreelands_get_uid_by_uuid($parcel_infos->parcel_owner);
		if (!$parcel_infos->parcel_owner_uid) {
			$context['results'][] = t('The parcel owner of parcel !name at !position, is not registered on the website. The owner is set to default owner.'
					, array('!name' => $parcel_infos->parcel_name, '!position' => $parcel_location));
			$parcel_infos->parcel_owner_uid = $default_owner_uid;
		}

		// save the parcel
		if (is_null($parcels_nids)) {
			// create a new parcel
			if($parcel_infos->parcel_owner != $default_owner_uuid) {
				$parcel_infos->parcel_status = 2;
			}
			$saved_parcel = osfreelands_save_parcel($parcel_infos);
			$result = t('Parcel named !name at !position created.', array('!name' => $parcel_infos->parcel_name, '!position' => $parcel_location));
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
