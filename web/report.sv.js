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
	$('#report thead tr th#https_provided').each( function() {
	    this.setAttribute( 'title', "Erbjuder webbplatsen HTTPS?");
	});
	$('#report thead tr th#https_required').each( function() {
	    this.setAttribute( 'title', "Kräver webbplatsen HTTPS?");
	});
	$('#report thead tr th#grade').each( function() {
	    this.setAttribute( 'title', "Betyg från Qualys SSL Labs");
	});
	$('#report thead tr th#dnssec').each( function() {
	    this.setAttribute( 'title', "Använder domänen DNSSEC?");
	});
	$('#report thead tr th#tlsa').each( function() {
	    this.setAttribute( 'title', "Finns TLSA-poster (DANE) publicerade för webbplatsen?");
	});

	var reportTable = $('#report').DataTable({	
		"pageLength": 25,
		"language": {
			"url": "https://cdn.datatables.net/plug-ins/1.10.7/i18n/Swedish.json"
		},
		"columns": [
			null,
			null,
			null,
			null,
			null,
			{ "type": "grade" },
			null,
			null
		]
	});

	reportTable.$('td').tooltip({
		"delay": 0,
		"track": true,
		"fade": 100
	});
});
