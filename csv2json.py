#!/usr/bin/python

import os
import csv
import json
from datetime import datetime

folder = 'shot-spotter'
csv_file = 'ShotSpotter.csv'

reader = csv.DictReader(open(os.sep.join([folder, csv_file])))

jobs = {}

for row in reader:
	# bucket those items with the same start and end date
	key = '-'.join((row['start date'], row['end date']))

	if key in jobs:
		jobs[key].append(row)
	else:
		jobs[key] = [row]

jobIdx = 1
for key, rules in jobs.iteritems():
	start_date = datetime.strptime(rules[0]['start date'], '%m/%d/%Y')
	end_date = datetime.strptime(rules[0]['end date'], '%m/%d/%Y') + + datetime.timedelta(days=1)

	job = {
		'publisher': 'twitter',
		'streamType': 'track',
		'dataFormat': 'original',
		'title': '%s-%03d' % (folder, jobIdx),
		'fromDate': start_date.strftime('%Y%m%d%H%M'),
		'toDate': end_date.strftime('%Y%m%d%H%M'),
		'rules': [],
	}

	for rule in rules:
		if rule['type:'] == 'circle':
			job['rules'].append({'value': 'point_radius:[{0} {1} {2}km]'.format(
				rule['center long'], rule['center lat'], rule['radius (km)']
			)})

		elif rule['type:'] == 'polygon':
			job['rules'].append({'value': 'bounding_box:[{0} {1} {2} {3}]'.format(
				rule['bottom left long'], rule['bottom left lat'], rule['top right long'], rule['top right lat']
			)})

	filename = os.sep.join([folder, '%s-%03d.json' % (folder, jobIdx)])
	print 'Writing file %s with %d rules' % (filename, len(rules))
	json.dump(job, open(filename, 'w'), indent=2)

	jobIdx += 1
