$.fn.dataTable.ext.type.order['grade-pre'] = function ( d ) {
	var grade = String(d).replace( /<[\s\S]*?>/g, "" );
	switch ( grade ) {
		case 'A+': return 1;
		case 'A':  return 2;
		case 'A-': return 3;
		case 'B+': return 4;
		case 'B':  return 5;
		case 'B-': return 6;
		case 'C+': return 7;
		case 'C':  return 8;
		case 'C-': return 9;
		case 'T':  return 10;
		case 'F':  return 99;
	}
	return 100;
};

$(document).ready(function() {
	$('#report').DataTable({	
		"pageLength": 25,
		"columns": [
			null,
			null,
			null,
			null,
			null,
			{ "type": "grade" }
		]
	});
});
