describe("Type Conversion", function() {

	it("local Date to ISO UTC String",function(){
		var values = {
			y: 2011,
			mo: 0,
			d: 1,
			h: 0,
			mi: 21,
			s: 36
		};
		var date = new Date(values['y'], values['mo'], values['d'], values['h'], values['mi'], values['s']);
		moment().zone(8);
		var actual = Kojac.interpretValueAsType(date,String);
		expect(actual).toEqual(_.format("{y}-{mo}-{d}T{h}:{mi}:{s}.000Z",{y:2010,mo:12,d:31,h:16,mi:21,s:36}));
	});

	it("ISO UTC String to local Date",function(){
		moment().zone(8);
		var actual = Kojac.interpretValueAsType("2010-12-31T16:21:36Z",Date);
		expect(actual).toEqual(new Date(2011,0,1,0,21,36));
	});

	it("ISO local String to local Date",function(){
		moment().zone(8);
		var actual = Kojac.interpretValueAsType("2011-01-01T00:21:36+08:00",Date);
		expect(actual).toEqual(new Date(2011,0,1,0,21,36));
	});

//	it("Number to Date",function(){
//
//	});
//
//	it("Date to Number",function(){
//
//	});

});
